public enum LLMProvider: String, Codable, CaseIterable {
    case openAI = "openai"
    case claude = "claude"

    /// Human-readable name for UI usage
    public var displayName: String {
        switch self {
        case .openAI: "OpenAI"
        case .claude: "Claude"
        }
    }
}
