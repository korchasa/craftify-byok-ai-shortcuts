import Foundation

/// Describes the capabilities of a Large Language Model client.
public protocol LLMClienting {
    /// Sends a text prompt along with a system prompt template and returns the generated text.
    /// - Parameters:
    ///   - messages: Array of chat messages prepared according to provider requirements.
    ///   - apiKey: Provider specific API key.
    /// - Returns: LLM generated text.
    func send(messages: [LLMMessage], apiKey: String) async throws -> String
}
