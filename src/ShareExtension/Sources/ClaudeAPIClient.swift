import Foundation

/// Client for sending requests to the Anthropic Claude API.
/// Default model `claude-sonnet-5` — the best speed/intelligence balance per
/// the Anthropic models overview (platform.claude.com/docs).
public final class ClaudeAPIClient: LLMClienting {
    private let session: URLSession
    private static let apiURLString = "https://api.anthropic.com/v1/messages"
    #if swift(>=5.9)
        // swiftlint:disable:next no_magic_numbers
    #endif
    private static let modelName = "claude-sonnet-5"
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

    private let apiURL = URL(string: ClaudeAPIClient.apiURLString)!
    /// Идентификатор модели; задаётся пользователем в настройках, по умолчанию — из каталога
    public let model: String
    private let temperature: Double = ClaudeAPIClient.defaultTemperature
    private let maxTokens: Int = ClaudeAPIClient.defaultMaxTokens
    private let maxRetries = ClaudeAPIClient.maxRetryCount
    private let retryDelays: [UInt64] = ClaudeAPIClient.retryDelaysSeconds.map { $0 * ClaudeAPIClient.nanosecondsPerSecond }

    public init(session: URLSession = .shared, model: String? = nil) {
        self.session = session
        self.model = model ?? ClaudeAPIClient.modelName
    }

    deinit {}

    public func send(messages: [LLMMessage], apiKey: String) async throws -> String {
        var lastError: Error?
        for attempt in 0 ..< maxRetries {
            do {
                var request = URLRequest(url: apiURL)
                request.httpMethod = "POST"
                request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
                request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                // Anthropic expects system prompt separate and messages array without system role
                let systemContent = messages.first(where: { $0.role == .system })?.content ?? ""
                let userAssistantMessages = messages.filter { $0.role != .system }
                let formattedMessages: [[String: Any]] = userAssistantMessages.map { msg in
                    [
                        "role": msg.role.rawValue,
                        "content": [["type": "text", "text": msg.content]]
                    ]
                }
                let body: [String: Any] = [
                    "model": model,
                    "temperature": temperature,
                    "max_tokens": maxTokens,
                    "system": systemContent,
                    "messages": formattedMessages
                ]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)

                let (data, response) = try await session.data(for: request)
                try Task.checkCancellation()
                guard let http = response as? HTTPURLResponse else {
                    throw LLMAPIClientError.invalidResponse("No HTTPURLResponse")
                }
                switch http.statusCode {
                case ClaudeAPIClient.httpStatusOK:
                    // Parse JSON
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let contentArr = json["content"] as? [[String: Any]],
                       let firstElement = contentArr.first,
                       let content = firstElement["text"] as? String
                    {
                        return content
                    }
                    throw LLMAPIClientError.invalidResponse("Missing content")
                case ClaudeAPIClient.httpStatusUnauthorized:
                    throw LLMAPIClientError.unauthorized
                case ClaudeAPIClient.httpStatusTooManyRequests:
                    if attempt < maxRetries - 1 {
                        try await Task.sleep(nanoseconds: retryDelays[attempt])
                        continue
                    }
                    throw LLMAPIClientError.tooManyRequests
                case ClaudeAPIClient.httpStatusServerErrorLowerBound ..< ClaudeAPIClient.httpStatusServerErrorUpperBound:
                    throw LLMAPIClientError.serverError
                default:
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let err = json["error"] as? [String: Any],
                       let message = err["message"] as? String
                    {
                        throw LLMAPIClientError.invalidResponse(message)
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
