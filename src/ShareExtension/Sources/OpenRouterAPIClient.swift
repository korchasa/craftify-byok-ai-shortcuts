import Foundation

/// Client for sending requests to the OpenRouter unified Chat Completion API.
/// Default model: `openai/gpt-5.6-luna`. API docs: https://openrouter.ai/docs/quickstart
public final class OpenRouterAPIClient: LLMClienting {
    private let session: URLSession
    private static let apiURLString = "https://openrouter.ai/api/v1/chat/completions"
    private static let modelName = "openai/gpt-5.6-luna"
    private static let defaultTemperature: Double = 0.7
    private static let defaultMaxTokens: Int = 2048
    /// Request timeout (sec)
    public static let requestTimeout: TimeInterval = 15
    private static let maxRetryCount = 3
    private static let retryDelayFirst: UInt64 = 1
    private static let retryDelaySecond: UInt64 = 2
    private static let retryDelayThird: UInt64 = 5
    private static let retryDelaysSeconds: [UInt64] = [retryDelayFirst, retryDelaySecond, retryDelayThird]
    private static let nanosecondsPerSecond: UInt64 = 1_000_000_000
    private static let httpStatusOK = 200
    private static let httpStatusBadRequest = 400
    private static let httpStatusUnauthorized = 401
    private static let httpStatusTooManyRequests = 429
    private static let httpStatusServerErrorLowerBound = 500
    private static let httpStatusServerErrorUpperBound = 600

    private let apiURL = URL(string: OpenRouterAPIClient.apiURLString)!
    /// Идентификатор модели; задаётся пользователем в настройках, по умолчанию — из каталога
    public let model: String
    private let temperature: Double = OpenRouterAPIClient.defaultTemperature
    private let maxTokens: Int = OpenRouterAPIClient.defaultMaxTokens
    private let maxRetries = OpenRouterAPIClient.maxRetryCount
    private let retryDelays: [UInt64] = OpenRouterAPIClient.retryDelaysSeconds.map { $0 * OpenRouterAPIClient.nanosecondsPerSecond }

    public init(session: URLSession = .shared, model: String? = nil) {
        self.session = session
        self.model = model ?? OpenRouterAPIClient.modelName
    }

    deinit {}

    public func send(messages: [LLMMessage], apiKey: String) async throws -> String {
        var lastError: Error?
        for attempt in 0 ..< maxRetries {
            do {
                var request = URLRequest(url: apiURL)
                request.httpMethod = "POST"
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                // Optional headers for leaderboard visibility are omitted.

                let messagesArray: [[String: String]] = messages.map { ["role": $0.role.rawValue, "content": $0.content] }
                let body: [String: Any] = [
                    "model": model,
                    "messages": messagesArray,
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
                case OpenRouterAPIClient.httpStatusOK:
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let message = choices.first? ["message"] as? [String: Any],
                       let content = message["content"] as? String
                    {
                        return content
                    }
                    throw LLMAPIClientError.invalidResponse("Missing result/content")
                case OpenRouterAPIClient.httpStatusUnauthorized:
                    throw LLMAPIClientError.unauthorized
                case OpenRouterAPIClient.httpStatusTooManyRequests:
                    if attempt < maxRetries - 1 {
                        try await Task.sleep(nanoseconds: retryDelays[attempt])
                        continue
                    }
                    throw LLMAPIClientError.tooManyRequests
                case OpenRouterAPIClient.httpStatusServerErrorLowerBound ..< OpenRouterAPIClient.httpStatusServerErrorUpperBound:
                    throw LLMAPIClientError.serverError
                default:
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let err = json["error"] as? [String: Any],
                       let msg = err["message"] as? String
                    {
                        // Проба 2026-07-15: неизвестная модель → 400,
                        // {"error":{"message":"<model> is not a valid model ID","code":400}}
                        if http.statusCode == OpenRouterAPIClient.httpStatusBadRequest,
                           msg.hasSuffix("is not a valid model ID")
                        {
                            throw LLMAPIClientError.unknownModel(model)
                        }
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
                if attempt < maxRetries - 1 {
                    try await Task.sleep(nanoseconds: retryDelays[attempt])
                    continue
                }
                throw LLMAPIClientError.network(urlError)
            } catch {
                // Несуществующая модель не станет существующей от повтора
                if case LLMAPIClientError.unknownModel = error {
                    throw error
                }
                lastError = error
                if attempt < maxRetries - 1 {
                    try await Task.sleep(nanoseconds: retryDelays[attempt])
                    continue
                }
                throw error
            }
        }
        throw lastError ?? LLMAPIClientError.unknown(-1)
    }
}
