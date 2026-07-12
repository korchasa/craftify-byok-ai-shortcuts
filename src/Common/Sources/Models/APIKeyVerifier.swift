import Foundation

/// Проверяет действительность API-ключа дешёвым запросом к списку моделей провайдера
public struct APIKeyVerifier: APIKeyVerifying {
    private static let requestTimeout: TimeInterval = 15
    private static let validStatusCodes = 200 ..< 300
    private static let unauthorizedStatusCode = 401
    private static let forbiddenStatusCode = 403
    private static let rejectedStatusCodes: Set<Int> = [unauthorizedStatusCode, forbiddenStatusCode]

    private let session: URLSession

    /// Инициализация с сессией (для тестов можно подменить)
    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Проверяет ключ запросом без токенов генерации; 401/403 — ключ отклонён,
    /// прочие сбои считаются недоступностью провайдера, а не ошибкой ключа.
    public func verify(key: String, provider: LLMProvider) async -> APIKeyVerificationOutcome {
        var request = URLRequest(url: Self.endpoint(for: provider))
        request.timeoutInterval = Self.requestTimeout
        switch provider {
        case .claude:
            request.setValue(key, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        case .openAI, .mistral, .openRouter:
            request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }
        do {
            let (_, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return .unreachable
            }
            if Self.validStatusCodes.contains(http.statusCode) {
                return .valid
            }
            if Self.rejectedStatusCodes.contains(http.statusCode) {
                return .invalid
            }
            return .unreachable
        } catch {
            return .unreachable
        }
    }

    private static func endpoint(for provider: LLMProvider) -> URL {
        let urlString = switch provider {
        case .openAI: "https://api.openai.com/v1/models"
        case .claude: "https://api.anthropic.com/v1/models"
        case .mistral: "https://api.mistral.ai/v1/models"
        // Список моделей OpenRouter публичный, поэтому ключ проверяется отдельной ручкой
        case .openRouter: "https://openrouter.ai/api/v1/auth/key"
        }
        guard let url = URL(string: urlString) else {
            fatalError("Invalid verification endpoint: \(urlString)")
        }
        return url
    }
}
