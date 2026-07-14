import Foundation

/// Загружает список моделей с эндпоинта `/v1/models` провайдера.
/// Все четыре провайдера отвечают JSON вида `{ "data": [ { "id": "..." }, ... ] }`.
public final class LLMModelListFetcher: ModelListFetching {
    private static let requestTimeout: TimeInterval = 15
    private static let validStatusCodes = 200 ..< 300
    /// Anthropic отдаёт страницы; берём максимально допустимый размер страницы
    private static let anthropicPageLimit = 1000

    private let session: URLSession

    /// Инициализация с сессией (для тестов можно подменить)
    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Запрашивает список моделей и возвращает отсортированные идентификаторы
    public func fetchModels(provider: LLMProvider, apiKey: String?) async throws -> [String] {
        var request = URLRequest(url: Self.endpoint(for: provider))
        request.timeoutInterval = Self.requestTimeout
        if let apiKey, !apiKey.isEmpty {
            switch provider {
            case .claude:
                request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
                request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            case .openAI, .mistral, .openRouter:
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            }
        }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, Self.validStatusCodes.contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try Self.parseModelIds(from: data)
    }

    /// Достаёт идентификаторы из `{ "data": [ { "id": ... } ] }` и сортирует их
    private static func parseModelIds(from data: Data) throws -> [String] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = json["data"] as? [[String: Any]]
        else {
            throw URLError(.cannotParseResponse)
        }
        let ids = items.compactMap { $0["id"] as? String }.filter { !$0.isEmpty }
        guard !ids.isEmpty else {
            throw URLError(.cannotParseResponse)
        }
        return Array(Set(ids)).sorted()
    }

    private static func endpoint(for provider: LLMProvider) -> URL {
        let urlString = switch provider {
        case .openAI: "https://api.openai.com/v1/models"
        case .claude: "https://api.anthropic.com/v1/models?limit=\(anthropicPageLimit)"
        case .mistral: "https://api.mistral.ai/v1/models"
        // Список моделей OpenRouter публичный — работает и без ключа
        case .openRouter: "https://openrouter.ai/api/v1/models"
        }
        guard let url = URL(string: urlString) else {
            fatalError("Invalid models endpoint: \(urlString)")
        }
        return url
    }

    deinit {}
}
