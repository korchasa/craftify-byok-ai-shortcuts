import Foundation

/// Client for sending requests to OpenAI Chat Completions API.
/// Default model `gpt-5.6-luna` — cost-efficient tier per platform.openai.com/docs/models.
public final class OpenAIAPIClient: LLMClienting {
    // The implementation is identical to the previous LLMAPIClient but with a new name.
    private let session: URLSession
    private static let apiURLString = "https://api.openai.com/v1/chat/completions"
    private static let modelName = "gpt-5.6-luna"
    /// Request timeout (sec)
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

    private let apiURL = URL(string: OpenAIAPIClient.apiURLString)!
    /// Идентификатор модели; задаётся пользователем в настройках, по умолчанию — из каталога
    public let model: String
    private let maxRetries = OpenAIAPIClient.maxRetryCount
    private let retryDelays: [UInt64] = OpenAIAPIClient.retryDelaysSeconds.map { $0 * OpenAIAPIClient.nanosecondsPerSecond }

    public init(session: URLSession = .shared, model: String? = nil) {
        self.session = session
        self.model = model ?? OpenAIAPIClient.modelName
    }

    deinit {}

    public func send(messages: [LLMMessage], apiKey: String) async throws -> String {
        var lastError: Error?
        for attempt in 0 ..< maxRetries {
            do {
                let request = try makeRequest(messages: messages, apiKey: apiKey, stream: false)
                let (data, response) = try await session.data(for: request)
                try Task.checkCancellation()
                guard let http = response as? HTTPURLResponse else {
                    throw LLMAPIClientError.invalidResponse("No HTTPURLResponse")
                }
                switch http.statusCode {
                case OpenAIAPIClient.httpStatusOK:
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
                    if let bodyError = LLMHTTPErrorMapper.errorInSuccessBody(data: data, model: model) {
                        throw bodyError
                    }
                    throw LLMAPIClientError.invalidResponse("Missing result/content")
                default:
                    throw LLMHTTPErrorMapper.error(statusCode: http.statusCode, data: data, model: model)
                }
            } catch is CancellationError {
                throw LLMAPIClientError.cancelled
            } catch let urlError as URLError where urlError.code == .cancelled {
                throw LLMAPIClientError.cancelled
            } catch let urlError as URLError {
                lastError = urlError
                if attempt < OpenAIAPIClient.lastRetryIndex {
                    try await Task.sleep(nanoseconds: retryDelays[attempt])
                    continue
                }
                throw LLMAPIClientError.network(urlError)
            } catch {
                if let llmError = error as? LLMAPIClientError, !llmError.isRetryable {
                    throw error
                }
                lastError = error
                if attempt < OpenAIAPIClient.lastRetryIndex {
                    try await Task.sleep(nanoseconds: retryDelays[attempt])
                    continue
                }
                throw error
            }
        }
        throw lastError ?? LLMAPIClientError.unknown(OpenAIAPIClient.unknownErrorCode)
    }

    /// Собирает запрос к API; `stream` просит отдавать ответ по кускам
    private func makeRequest(messages: [LLMMessage], apiKey: String, stream: Bool) throws -> URLRequest {
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let messagesArray: [[String: String]] = messages.map { ["role": $0.role.rawValue, "content": $0.content] }
        // Модели GPT-5 отвергают `max_tokens` и любую `temperature`, кроме 1, а в
        // `max_completion_tokens` входят токены рассуждения: при малом лимите модель
        // тратит его целиком на рассуждение и возвращает пустой ответ. Оба параметра
        // необязательны, поэтому не передаём ни один.
        var body: [String: Any] = [
            "model": model,
            "messages": messagesArray
        ]
        if stream {
            body["stream"] = true
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    public func stream(messages: [LLMMessage], apiKey: String) -> AsyncThrowingStream<String, Error> {
        // [REF:fr:ux.streaming]
        let request: URLRequest
        do {
            request = try makeRequest(messages: messages, apiKey: apiKey, stream: true)
        } catch {
            return AsyncThrowingStream { $0.finish(throwing: error) }
        }
        let requestedModel = model
        return LLMEventStream.run(request: request, session: session, model: requestedModel) { _, data in
            try LLMStreamParsing.openAIChatPiece(data: data, model: requestedModel)
        }
    }
}
