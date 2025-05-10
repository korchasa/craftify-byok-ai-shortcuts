import Foundation

/// Структура для пользовательских ошибок с поддержкой локализации
public struct UserFacingError: LocalizedError, Equatable {
    public let titleKey: UserFacingErrorKey
    public let messageKey: UserFacingErrorKey
    public let adviceKey: UserFacingErrorKey
    public let underlyingError: Error?

    public init(messageKey: UserFacingErrorKey, adviceKey: UserFacingErrorKey, titleKey: UserFacingErrorKey = .error, underlyingError: Error? = nil) {
        self.titleKey = titleKey
        self.messageKey = messageKey
        self.adviceKey = adviceKey
        self.underlyingError = underlyingError
    }

    public var messageKeyString: String { messageKey.rawValue }
    public var adviceKeyString: String { adviceKey.rawValue }
    public var titleKeyString: String { titleKey.rawValue }

    public var errorDescription: String? {
        nil
    }

    public var failureReason: String? {
        nil
    }

    public var recoverySuggestion: String? {
        nil
    }

    public static func unknown(underlyingError: Error? = nil) -> UserFacingError {
        UserFacingError(
            messageKey: .adviceUnknownError,
            adviceKey: .adviceContactSupport,
            underlyingError: underlyingError
        )
    }

    public static func == (lhs: UserFacingError, rhs: UserFacingError) -> Bool {
        lhs.messageKey == rhs.messageKey &&
            lhs.adviceKey == rhs.adviceKey &&
            lhs.titleKey == rhs.titleKey
    }
}
