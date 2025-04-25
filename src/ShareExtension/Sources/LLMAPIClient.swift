import Common
import Foundation

/// Клиент для отправки запросов к OpenAI API (gpt-4o-mini)
public final class LLMAPIClient {
    private let session: URLSession
    private static let apiURLString = "https://api.openai.com/v1/chat/completions"
    private static let modelName = "gpt-4o-mini"
    private static let defaultTemperature: Double = 0.7
    private static let defaultMaxTokens: Int = 2048
    /// Таймаут запроса (сек)
    public static let requestTimeout: TimeInterval = 15
    private static let maxRetryCount = 3
    private static let retryDelayFirst: UInt64 = 1
    private static let retryDelaySecond: UInt64 = 2
    private static let retryDelayThird: UInt64 = 5
    private static let retryDelaysSeconds: [UInt64] = [retryDelayFirst, retryDelaySecond, retryDelayThird]
    private static let retryIndexOffset = 1
    private static let lastRetryIndex = maxRetryCount - retryIndexOffset
    private static let unknownErrorCode = -1
    private static let nanosecondsPerSecond: UInt64 = 1_000_000_000
    private static let httpStatusOK = 200
    private static let httpStatusUnauthorized = 401
    private static let httpStatusTooManyRequests = 429
    private static let httpStatusServerError = 500

    private let apiURL = URL(string: LLMAPIClient.apiURLString)!
    private let model = LLMAPIClient.modelName
    private let temperature: Double = LLMAPIClient.defaultTemperature
    private let maxTokens: Int = LLMAPIClient.defaultMaxTokens
    private let maxRetries = LLMAPIClient.maxRetryCount
    private let retryDelays: [UInt64] = LLMAPIClient.retryDelaysSeconds.map { $0 * LLMAPIClient.nanosecondsPerSecond } // ns

    /// Инициализация клиента LLMAPIClient
    /// - Parameter session: URLSession (по умолчанию .shared)
    public init(session: URLSession = .shared) {
        self.session = session
    }

    deinit {}

    /// Отправить запрос к OpenAI API
    /// - Parameters:
    ///   - text: Текст пользователя
    ///   - promptTemplate: Шаблон промпта
    ///   - apiKey: API-ключ OpenAI
    /// - Returns: Результат обработки текста
    /// - Throws: LLMAPIClientError или другую ошибку
    public func send(text: String, promptTemplate: String, apiKey: String) async throws -> String {
        var lastError: Error?
        for attempt in 0 ..< maxRetries {
            do {
                var request = URLRequest(url: apiURL)
                request.httpMethod = "POST"
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                let body: [String: Any] = [
                    "model": model,
                    "messages": [
                        ["role": "system", "content": promptTemplate],
                        ["role": "user", "content": text]
                    ],
                    "temperature": temperature,
                    "max_tokens": maxTokens
                ]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                let (data, response) = try await session.data(for: request)
                try Task.checkCancellation()
                guard let http = response as? HTTPURLResponse else {
                    throw LLMAPIClientError.invalidResponse("No HTTPURLResponse")
                }
                switch http.statusCode {
                case LLMAPIClient.httpStatusOK:
                    // Парсим JSON-ответ
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    if let choices = json?["choices"] as? [[String: Any]],
                       let message = choices.first?["message"] as? [String: Any],
                       let content = message["content"] as? String
                    {
                        return content
                    }
                    if let result = json?["result"] as? String {
                        return result
                    }
                    throw LLMAPIClientError.invalidResponse("Нет поля result/content")
                case LLMAPIClient.httpStatusUnauthorized:
                    throw LLMAPIClientError.unauthorized
                case LLMAPIClient.httpStatusTooManyRequests:
                    if attempt < LLMAPIClient.lastRetryIndex {
                        try await Task.sleep(nanoseconds: retryDelays[attempt])
                        continue
                    }
                    throw LLMAPIClientError.tooManyRequests
                case LLMAPIClient.httpStatusServerError:
                    throw LLMAPIClientError.serverError
                default:
                    // Пробуем вытащить error.message
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let err = json["error"] as? [String: Any],
                       let msg = err["message"] as? String
                    {
                        throw LLMAPIClientError.invalidResponse(msg)
                    }
                    throw LLMAPIClientError.unknown(http.statusCode)
                }
            } catch is CancellationError {
                throw LLMAPIClientError.cancelled
            } catch let urlError as URLError where urlError.code == .cancelled {
                throw LLMAPIClientError.cancelled
            } catch let urlError as URLError {
                lastError = urlError
                if attempt < LLMAPIClient.lastRetryIndex {
                    try await Task.sleep(nanoseconds: retryDelays[attempt])
                    continue
                }
                throw LLMAPIClientError.network(urlError)
            } catch {
                lastError = error
                if attempt < LLMAPIClient.lastRetryIndex {
                    try await Task.sleep(nanoseconds: retryDelays[attempt])
                    continue
                }
                throw error
            }
        }
        throw lastError ?? LLMAPIClientError.unknown(LLMAPIClient.unknownErrorCode)
    }
}
