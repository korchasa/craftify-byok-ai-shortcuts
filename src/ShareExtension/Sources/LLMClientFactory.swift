import Foundation

/// Factory responsible for instantiating a concrete `LLMClienting` implementation
/// depending on the selected `LLMProvider`.
public enum LLMClientFactory {
    /// Returns a concrete client for the given provider.
    /// - Parameter provider: Provider to create client for.
    /// - Returns: `LLMClienting` instance.
    public static func make(provider: LLMProvider) -> LLMClienting {
        switch provider {
        case .openAI:
            OpenAIAPIClient()
        case .claude:
            ClaudeAPIClient()
        case .mistral:
            MistralAPIClient()
        case .openRouter:
            OpenRouterAPIClient()
        }
    }
}
