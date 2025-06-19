import Foundation

/// Represents a single chat message that will be sent to an LLM provider.
/// Follows the OpenAI/Mistral role naming convention.
public struct LLMMessage: Codable, Equatable {
    /// Chat role (system, user, assistant, etc.)
    public enum Role: String, Codable {
        case system = "system"
        case user = "user"
        case assistant = "assistant"
    }

    /// Role of the message sender.
    public let role: Role
    /// Text content of the message.
    public let content: String

    public init(role: Role, content: String) {
        self.role = role
        self.content = content
    }
}
