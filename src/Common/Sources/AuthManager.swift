import Foundation
import Security

/// Production-реализация AuthManaging с поддержкой Keychain Sharing (App Group)
public final class AuthManager: AuthManaging, @unchecked Sendable {
    private let service = "dev.korchasa.Craftify.OpenAIKey"
    private let accessGroup = "78M3ZDR5UH.group.dev.korchasa.Craftify"

    public init() {}

    /// Получить API-ключ (или nil, если не найден)
    public func getAPIKey() async throws -> String? {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            guard self != nil else {
                continuation.resume(returning: nil)
                return
            }
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let key = try self!.getAPIKeySync()
                    continuation.resume(returning: key)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func getAPIKeySync() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccessGroup as String: accessGroup,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess:
            guard let data = item as? Data, let key = String(data: data, encoding: .utf8) else {
                throw AuthManagerError.itemNotFound
            }
            return key
        case errSecItemNotFound:
            return nil
        case errSecMissingEntitlement:
            // Treat missing entitlement as no key found to avoid error on initial settings view
            return nil
        case errSecAuthFailed:
            throw AuthManagerError.accessDenied
        case errSecInteractionNotAllowed:
            return nil
        default:
            throw AuthManagerError.itemNotFound
        }
    }

    /// Сохранить API-ключ
    public func setAPIKey(_ key: String) async throws {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            guard self != nil else {
                continuation.resume()
                return
            }
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try self!.setAPIKeySync(key)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func setAPIKeySync(_ key: String) throws {
        guard !key.isEmpty else {
            throw AuthManagerError.invalidKey
        }
        let data = key.data(using: .utf8) ?? Data()
        try? deleteAPIKeySync()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccessGroup as String: accessGroup,
            kSecValueData as String: data
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        switch status {
        case errSecSuccess:
            return
        case errSecMissingEntitlement, errSecAuthFailed:
            throw AuthManagerError.accessDenied
        case errSecInteractionNotAllowed:
            throw AuthManagerError.itemNotFound
        default:
            throw AuthManagerError.itemNotFound
        }
    }

    /// Удалить API-ключ
    public func deleteAPIKey() async throws {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            guard self != nil else {
                continuation.resume()
                return
            }
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try self!.deleteAPIKeySync()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func deleteAPIKeySync() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccessGroup as String: accessGroup
        ]
        let status = SecItemDelete(query as CFDictionary)
        switch status {
        case errSecSuccess, errSecItemNotFound:
            return
        case errSecMissingEntitlement, errSecAuthFailed:
            throw AuthManagerError.accessDenied
        case errSecInteractionNotAllowed:
            return
        default:
            throw AuthManagerError.itemNotFound
        }
    }

    /// Маскирует API-ключ для логирования
    public func maskedAPIKey(_ key: String?) -> String {
        maskKey(key)
    }

    deinit {}
}
