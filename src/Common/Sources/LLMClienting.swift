import Foundation

/// Describes the capabilities of a Large Language Model client.
public protocol LLMClienting {
    /// Sends a text prompt along with a system prompt template and returns the generated text.
    /// - Parameters:
    ///   - text: User provided text.
    ///   - promptTemplate: System prompt template.
    ///   - apiKey: Provider specific API key.
    /// - Returns: LLM generated text.
    func send(text: String, promptTemplate: String, apiKey: String) async throws -> String
}
