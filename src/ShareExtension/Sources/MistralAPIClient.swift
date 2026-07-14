import Foundation

/// Client for sending requests to the Mistral Chat Completion API.
/// Default model `mistral-medium-3-5` — frontier generalist per docs.mistral.ai/models.
/// API reference: https://docs.mistral.ai/api/
public final class MistralAPIClient: LLMClienting {
    private let session: URLSession
    private static let apiURLString = "https://api.mistral.ai/v1/chat/completions"
    private static let modelName = "mistral-medium-3-5"
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
    private static let httpStatusUnauthorized = 401
    private static let httpStatusTooManyRequests = 429
    private static let httpStatusServerErrorLowerBound = 500
    private static let httpStatusServerErrorUpperBound = 600

    private let apiURL = URL(string: MistralAPIClient.apiURLString)!
    /// Идентификатор модели; задаётся пользователем в настройках, по умолчанию — из каталога
    public let model: String
    private let temperature: Double = MistralAPIClient.defaultTemperature
    private let maxTokens: Int = MistralAPIClient.defaultMaxTokens
    private let maxRetries = MistralAPIClient.maxRetryCount
    private let retryDelays: [UInt64] = MistralAPIClient.retryDelaysSeconds.map { $0 * MistralAPIClient.nanosecondsPerSecond }

    public init(session: URLSession = .shared, model: String? = nil) {
        self.session = session
        self.model = model ?? MistralAPIClient.modelName
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
                case MistralAPIClient.httpStatusOK:
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let message = choices.first?["message"] as? [String: Any],
                       let content = message["content"] as? String
                    {
                        return content
                    }
                    throw LLMAPIClientError.invalidResponse("Missing result/content")
                case MistralAPIClient.httpStatusUnauthorized:
                    throw LLMAPIClientError.unauthorized
                case MistralAPIClient.httpStatusTooManyRequests:
                    if attempt < maxRetries - 1 {
                        try await Task.sleep(nanoseconds: retryDelays[attempt])
                        continue
                    }
                    throw LLMAPIClientError.tooManyRequests
                case MistralAPIClient.httpStatusServerErrorLowerBound ..< MistralAPIClient.httpStatusServerErrorUpperBound:
                    throw LLMAPIClientError.serverError
                default:
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
                if attempt < maxRetries - 1 {
                    try await Task.sleep(nanoseconds: retryDelays[attempt])
                    continue
                }
                throw LLMAPIClientError.network(urlError)
            } catch {
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
