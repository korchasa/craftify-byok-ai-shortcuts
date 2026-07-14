import Foundation

/// Модели по умолчанию для провайдеров LLM (проверены по официальной документации, июль 2026).
/// Список для выбора всегда загружается с API провайдера — статического каталога нет.
public enum LLMModelCatalog {
    /// Модель по умолчанию для нового пользователя или пустой настройки
    public static func defaultModel(for provider: LLMProvider) -> String {
        switch provider {
        case .openAI:
            "gpt-5.6-luna"
        case .claude:
            "claude-sonnet-5"
        case .mistral:
            "mistral-medium-3-5"
        case .openRouter:
            "openai/gpt-5.6-luna"
        }
    }
}
