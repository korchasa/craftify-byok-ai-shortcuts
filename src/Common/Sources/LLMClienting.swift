import Foundation

/// Describes the capabilities of a Large Language Model client.
public protocol LLMClienting {
    /// Sends a text prompt along with a system prompt template and returns the generated text.
    /// - Parameters:
    ///   - messages: Array of chat messages prepared according to provider requirements.
    ///   - apiKey: Provider specific API key.
    /// - Returns: LLM generated text.
    func send(messages: [LLMMessage], apiKey: String) async throws -> String

    /// Sends the same request but returns the answer piece by piece, as the model writes it.
    /// - Parameters:
    ///   - messages: Array of chat messages prepared according to provider requirements.
    ///   - apiKey: Provider specific API key.
    /// - Returns: A stream of text pieces; joined, they form the whole answer.
    func stream(messages: [LLMMessage], apiKey: String) -> AsyncThrowingStream<String, Error>
}

public extension LLMClienting {
    /// Клиент без потокового режима отдаёт весь ответ одним куском
    func stream(messages: [LLMMessage], apiKey: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let text = try await send(messages: messages, apiKey: apiKey)
                    continuation.yield(text)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
