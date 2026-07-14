import Foundation

/// Каталог моделей LLM-провайдеров: значения по умолчанию и актуальные списки для выбора в настройках.
/// Списки собраны из официальных источников (июль 2026):
/// OpenAI — platform.openai.com/docs/models; Anthropic — platform.claude.com/docs (models overview);
/// Mistral — docs.mistral.ai/models (карточки моделей); OpenRouter — живой список openrouter.ai/api/v1/models.
public enum LLMModelCatalog {
    /// Модель по умолчанию — первая в актуальном списке провайдера
    public static func defaultModel(for provider: LLMProvider) -> String {
        curatedModels(for: provider)[0]
    }

    /// Актуальный список моделей для выбора; первая — модель по умолчанию
    public static func curatedModels(for provider: LLMProvider) -> [String] {
        switch provider {
        case .openAI:
            ["gpt-5.6-luna", "gpt-5.6-terra", "gpt-5.6-sol"]
        case .claude:
            ["claude-sonnet-5", "claude-haiku-4-5", "claude-opus-4-8", "claude-fable-5"]
        case .mistral:
            ["mistral-medium-3-5", "mistral-small-2603", "mistral-large-2512"]
        case .openRouter:
            [
                "openai/gpt-5.6-luna",
                "openai/gpt-5.6-terra",
                "openai/gpt-5.6-sol",
                "anthropic/claude-sonnet-5",
                "anthropic/claude-opus-4.8",
                "anthropic/claude-fable-5",
                "google/gemini-3.5-flash",
                "mistralai/mistral-medium-3-5",
                "deepseek/deepseek-v4-flash"
            ]
        }
    }
}
