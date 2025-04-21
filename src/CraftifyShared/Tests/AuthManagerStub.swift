@testable import CraftifyShared
import Foundation

/// Заглушка для AuthManager, используемая в тестах
public final class AuthManagerStub: AuthManaging {
    // MARK: - Constants

    private static let validKeyLength = 16
    private static let maskLength = 8
    private static let prefixLength = 3
    private static let suffixLength = 4

    // MARK: - Properties

    public var shouldThrow: AuthManagerError?
    private var key: String?

    // MARK: - AuthManaging

    /// Получить API-ключ
    public func getAPIKey() throws -> String? {
        if let error = shouldThrow {
            throw error
        }
        return key
    }

    /// Установить API-ключ
    public func setAPIKey(_ key: String) throws {
        if let error = shouldThrow {
            throw error
        }
        guard key.count >= Self.validKeyLength else {
            throw AuthManagerError.invalidKey
        }
        self.key = key
    }

    /// Удалить API-ключ
    public func deleteAPIKey() throws {
        if let error = shouldThrow {
            throw error
        }
        self.key = nil
    }

    /// Маскирует API-ключ для логирования
    public func maskedAPIKey(_ key: String?) -> String {
        guard let key, key.count >= Self.maskLength else {
            return String(repeating: "*", count: Self.maskLength)
        }
        let prefix = key.prefix(Self.prefixLength)
        let suffix = key.suffix(Self.suffixLength)
        return "\(prefix)****\(suffix)"
    }

    // MARK: - Жизненный цикл

    /// Очистка ресурсов (stub)
    deinit {
        // nothing to cleanup
    }
}
