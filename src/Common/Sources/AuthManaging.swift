import Foundation

/// Протокол для безопасного хранения и получения API-ключа OpenAI
public protocol AuthManaging: AnyObject {
    /// Получить API-ключ (или nil, если не найден)
    func getAPIKey() async throws -> String?
    /// Сохранить API-ключ
    func setAPIKey(_ key: String) async throws
    /// Удалить API-ключ
    func deleteAPIKey() async throws
    /// Вернуть маскированный ключ (например, sk-****abcd)
    func maskedAPIKey(_ key: String?) -> String
}
