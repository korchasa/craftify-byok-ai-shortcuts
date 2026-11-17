import Foundation

// [REF:fr:ux.streaming]
/// Выполняет потоковый запрос к провайдеру и отдаёт текст ответа по кускам.
/// Общая часть для всех клиентов: чтение строк событий, отказ по HTTP-коду, повтор при сбое
/// соединения и отмена. Формат событий конкретного провайдера разбирает переданная функция.
public enum LLMEventStream {
    /// Разбор одного события: поле `event:` (если было) и поле `data:`
    public typealias Parse = (_ event: String?, _ data: String) throws -> LLMStreamPiece

    private static let httpStatusOK = 200
    private static let dataPrefix = "data:"
    private static let eventPrefix = "event:"
    private static let commentPrefix = ":"
    private static let nanosecondsPerSecond: UInt64 = 1_000_000_000
    /// Паузы перед повтором после сбоя соединения — те же, что у обычного запроса
    private static let retryDelayFirst: UInt64 = 1
    private static let retryDelaySecond: UInt64 = 2
    private static let retryDelayThird: UInt64 = 5
    private static let retryDelaysSeconds: [UInt64] = [retryDelayFirst, retryDelaySecond, retryDelayThird]

    /// Запускает потоковый запрос
    /// - Parameters:
    ///   - request: Готовый запрос с флагом потоковой передачи в теле
    ///   - session: Сессия URLSession
    ///   - model: Запрошенная модель — для сообщения о недоступной модели
    ///   - parse: Разбор событий формата провайдера
    /// - Returns: Поток кусков текста
    public static func run(
        request: URLRequest,
        session: URLSession,
        model: String,
        parse: @escaping Parse
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await deliver(request: request, session: session, model: model, parse: parse, to: continuation)
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish(throwing: LLMAPIClientError.cancelled)
                } catch let urlError as URLError where urlError.code == .cancelled {
                    continuation.finish(throwing: LLMAPIClientError.cancelled)
                } catch let urlError as URLError {
                    continuation.finish(throwing: LLMAPIClientError.network(urlError))
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Повторяет запрос при сбое соединения, пока не пришло ни одного куска текста:
    /// после первого куска повтор продублировал бы уже показанный текст
    private static func deliver(
        request: URLRequest,
        session: URLSession,
        model: String,
        parse: @escaping Parse,
        to continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        var attempt = 0
        while true {
            var yieldedAny = false
            do {
                try await readOnce(request: request, session: session, model: model, parse: parse) { piece in
                    yieldedAny = true
                    continuation.yield(piece)
                }
                return
            } catch let urlError as URLError where urlError.code != .cancelled && !yieldedAny && attempt < retryDelaysSeconds.count - 1 {
                try await Task.sleep(nanoseconds: retryDelaysSeconds[attempt] * nanosecondsPerSecond)
                attempt += 1
            }
        }
    }

    private static func readOnce(
        request: URLRequest,
        session: URLSession,
        model: String,
        parse: Parse,
        yield: (String) -> Void
    ) async throws {
        let (bytes, response) = try await session.bytes(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw LLMAPIClientError.invalidResponse("No HTTPURLResponse")
        }
        guard http.statusCode == httpStatusOK else {
            // Отказ приходит обычным JSON-телом — читаем его целиком и разбираем как раньше
            var body = Data()
            for try await byte in bytes {
                body.append(byte)
            }
            throw LLMHTTPErrorMapper.error(statusCode: http.statusCode, data: body, model: model)
        }
        var event: String?
        for try await rawLine in bytes.lines {
            try Task.checkCancellation()
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix(commentPrefix) {
                continue
            }
            if line.hasPrefix(eventPrefix) {
                event = String(line.dropFirst(eventPrefix.count)).trimmingCharacters(in: .whitespaces)
                continue
            }
            guard line.hasPrefix(dataPrefix) else {
                continue
            }
            let data = String(line.dropFirst(dataPrefix.count)).trimmingCharacters(in: .whitespaces)
            switch try parse(event, data) {
            case let .text(piece):
                yield(piece)
            case .done:
                return
            case .skip:
                break
            }
            event = nil
        }
    }
}
