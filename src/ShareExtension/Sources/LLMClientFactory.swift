import Foundation

/// Factory responsible for instantiating a concrete `LLMClienting` implementation
/// depending on the selected `LLMProvider`.
public enum LLMClientFactory {
    /// Returns a concrete client for the given provider with the user-selected model injected.
    /// - Parameters:
    ///   - provider: Provider to create client for.
    ///   - settings: Settings store holding the per-provider model choice.
    /// - Returns: `LLMClienting` instance.
    public static func make(provider: LLMProvider, settings: AppSettingsManager = .shared) -> LLMClienting {
        let model = settings.model(for: provider)
        return switch provider {
        case .openAI:
            OpenAIAPIClient(model: model)
        case .claude:
            ClaudeAPIClient(model: model)
        case .mistral:
            MistralAPIClient(model: model)
        case .openRouter:
            OpenRouterAPIClient(model: model)
        }
    }
}
