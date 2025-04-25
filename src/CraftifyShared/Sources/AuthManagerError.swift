import Foundation

public enum AuthManagerError: Error, Equatable, LocalizedError {
    case accessDenied
    case invalidKey
    case itemNotFound

    public var errorDescription: String? {
        switch self {
        case .accessDenied:
            "Нет доступа к Keychain. Проверьте настройки Keychain Sharing и App Groups."
        case .invalidKey:
            "Неверный формат API-ключа. Пожалуйста, проверьте введённый ключ."
        case .itemNotFound:
            "API-ключ не найден. Пожалуйста, введите ключ."
        }
    }
}
