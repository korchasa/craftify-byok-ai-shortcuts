public enum LLMProvider: String, Codable, CaseIterable {
    case openAI = "openai"
    case claude = "claude"
    case mistral = "mistral"
    case openRouter = "openrouter"

    /// Human-readable name for UI usage
    public var displayName: String {
        switch self {
        case .openAI: "OpenAI"
        case .claude: "Claude"
        case .mistral: "Mistral"
        case .openRouter: "OpenRouter"
        }
    }
}
