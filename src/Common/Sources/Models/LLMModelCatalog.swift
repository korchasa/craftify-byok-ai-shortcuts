import Foundation

/// Каталог моделей LLM-провайдеров: значения по умолчанию и проверенные списки для выбора в настройках.
/// OpenRouter дополнительно принимает произвольный идентификатор модели (свободный ввод в настройках).
public enum LLMModelCatalog {
    /// Модель по умолчанию — прежние зашитые значения клиентов
    public static func defaultModel(for provider: LLMProvider) -> String {
        switch provider {
        case .openAI:
            "gpt-4o-mini"
        case .claude:
            "claude-sonnet-4-0"
        case .mistral:
            "mistral-medium-latest"
        case .openRouter:
            "openai/gpt-4o-mini"
        }
    }

    /// Проверенный список моделей для выбора; первая — модель по умолчанию
    public static func curatedModels(for provider: LLMProvider) -> [String] {
        switch provider {
        case .openAI:
            ["gpt-4o-mini", "gpt-4o", "gpt-4.1-mini", "gpt-4.1"]
        case .claude:
            ["claude-sonnet-4-0", "claude-3-5-haiku-latest", "claude-opus-4-0"]
        case .mistral:
            ["mistral-medium-latest", "mistral-small-latest", "mistral-large-latest"]
        case .openRouter:
            ["openai/gpt-4o-mini", "anthropic/claude-sonnet-4", "google/gemini-2.5-flash"]
        }
    }

    /// Провайдеры со свободным вводом модели (помимо списка)
    public static func allowsCustomModel(_ provider: LLMProvider) -> Bool {
        provider == .openRouter
    }
}
