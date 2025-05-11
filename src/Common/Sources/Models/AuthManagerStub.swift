import Foundation

/// Заглушка для AuthManager, используемая в тестах
public final class AuthManagerStub: AuthManaging {
    // MARK: - Constants

    private static let validKeyLength = 16

    // MARK: - Properties

    public var shouldThrow: AuthManagerError?
    public var shouldThrowAccessDenied: Bool = false
    private var key: String?

    /// Инициализация stub с дефолтным ключом или без ключа
    public init(key: String? = "sk-valid-key-1234567890") {
        self.key = key
    }

    // MARK: - AuthManaging

    /// Получить API-ключ (async stub)
    public func getAPIKey() async throws -> String? { // swiftlint:disable:this async_without_await
        if shouldThrowAccessDenied {
            throw AuthManagerError.accessDenied
        }
        return try getAPIKeySync()
    }

    private func getAPIKeySync() throws -> String? {
        if shouldThrowAccessDenied {
            throw AuthManagerError.accessDenied
        }
        if let error = shouldThrow {
            throw error
        }
        return key
    }

    /// Установить API-ключ (async stub)
    public func setAPIKey(_ key: String) async throws { // swiftlint:disable:this async_without_await
        if shouldThrowAccessDenied {
            throw AuthManagerError.accessDenied
        }
        try setAPIKeySync(key)
    }

    private func setAPIKeySync(_ key: String) throws {
        if shouldThrowAccessDenied {
            throw AuthManagerError.accessDenied
        }
        if let error = shouldThrow {
            throw error
        }
        guard key.count >= Self.validKeyLength else {
            throw AuthManagerError.invalidKey
        }
        self.key = key
    }

    /// Удалить API-ключ (async stub)
    public func deleteAPIKey() async throws { // swiftlint:disable:this async_without_await
        if shouldThrowAccessDenied {
            throw AuthManagerError.accessDenied
        }
        try deleteAPIKeySync()
    }

    private func deleteAPIKeySync() throws {
        if shouldThrowAccessDenied {
            throw AuthManagerError.accessDenied
        }
        if let error = shouldThrow {
            throw error
        }
        self.key = nil
    }

    /// Маскирует API-ключ для логирования
    public func maskedAPIKey(_ key: String?) -> String {
        maskKey(key)
    }

    public var savedKey: String? {
        get { key }
        set { key = newValue }
    }

    // MARK: - Жизненный цикл

    /// Очистка ресурсов (stub)
    deinit {
        // nothing to cleanup
    }
}
