import Foundation

/// Протокол проверки действительности API-ключа у провайдера
public protocol APIKeyVerifying: Sendable {
    /// Проверяет ключ дешёвым запросом к провайдеру
    func verify(key: String, provider: LLMProvider) async -> APIKeyVerificationOutcome
}
