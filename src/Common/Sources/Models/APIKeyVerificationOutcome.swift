import Foundation

/// Результат проверки API-ключа у провайдера
public enum APIKeyVerificationOutcome: Equatable, Sendable {
    /// Провайдер принял ключ
    case valid
    /// Провайдер отклонил ключ (401/403)
    case invalid
    /// Провайдер недоступен — судить о ключе нельзя
    case unreachable
}
