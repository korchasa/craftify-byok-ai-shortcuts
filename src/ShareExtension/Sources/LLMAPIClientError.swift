import Foundation

/// Common error types for LLM API clients (OpenAI, Claude, etc.)
public enum LLMAPIClientError: Error, LocalizedError, Equatable {
    case unauthorized
    /// У ключа кончились деньги или квота (402, а также 429 с признаком квоты)
    case insufficientCredits
    /// Ключу не разрешён этот запрос: нет прав или регион не поддерживается (403)
    case accessDenied
    /// Запрос отклонён фильтром безопасности провайдера
    case contentFiltered
    /// Текст не помещается в контекст модели либо запрос слишком велик (413, context_length_exceeded)
    case contextTooLong
    /// Провайдер не успел ответить (408, 504)
    case timedOut
    case tooManyRequests
    case serverError
    case cancelled
    /// Провайдер отклонил запрос и объяснил причину своим текстом (прочие 400 и 422)
    case badRequest(String)
    case invalidResponse(String)
    /// Провайдер не знает указанную модель либо она недоступна ключу (форма ответа проверена живой пробой)
    case unknownModel(String)
    case unknown(Int)
    case network(Error)

    public var userFacingError: UserFacingError {
        switch self {
        case .unauthorized:
            UserFacingError(
                messageKey: .errorInvalidApiKey,
                adviceKey: .adviceCheckApiKey
            )
        case .insufficientCredits:
            UserFacingError(
                messageKey: .errorInsufficientCredits,
                adviceKey: .adviceTopUpBalance
            )
        case .accessDenied:
            UserFacingError(
                messageKey: .errorAccessDenied,
                adviceKey: .adviceCheckKeyAccess
            )
        case .contentFiltered:
            UserFacingError(
                messageKey: .errorContentFiltered,
                adviceKey: .adviceChangeText
            )
        case .contextTooLong:
            UserFacingError(
                messageKey: .errorContextTooLong,
                adviceKey: .adviceShortenText
            )
        case .timedOut:
            UserFacingError(
                messageKey: .errorTimeout,
                adviceKey: .adviceTryAgainLater
            )
        case .tooManyRequests:
            UserFacingError(
                messageKey: .errorRateLimited,
                adviceKey: .adviceTryAgainLater
            )
        case .serverError:
            UserFacingError(
                messageKey: .errorProviderUnavailable,
                adviceKey: .adviceTryAgainLater
            )
        case .cancelled:
            UserFacingError(
                messageKey: .errorCancelled,
                adviceKey: .adviceTryAgainLater
            )
        case .badRequest:
            UserFacingError(
                messageKey: .errorProviderRejectedRequest,
                adviceKey: .adviceChangeText,
                underlyingError: self
            )
        case .invalidResponse:
            UserFacingError(
                messageKey: .errorParsing,
                adviceKey: .adviceTryAgainLater,
                underlyingError: self
            )
        case .unknownModel:
            UserFacingError(
                messageKey: .errorUnknownModel,
                adviceKey: .adviceChangeModel,
                underlyingError: self
            )
        case .unknown:
            UserFacingError.unknown(underlyingError: self)
        case .network:
            UserFacingError(
                messageKey: .errorNetwork,
                adviceKey: .adviceCheckConnection
            )
        }
    }

    /// Уточнение от провайдера, которое стоит показать под сообщением: его собственный текст
    /// или идентификатор модели. Для остальных случаев подробностей нет — сообщения достаточно.
    public var providerDetail: String? {
        let detail: String? = switch self {
        case let .badRequest(message), let .invalidResponse(message):
            message
        case let .unknownModel(model):
            model
        default:
            nil
        }
        // Пустое уточнение хуже отсутствующего: в алерте оно превратится в лишний отступ
        guard let detail, !detail.isEmpty else {
            return nil
        }
        return detail
    }

    /// Имеет ли смысл повторять запрос. Неверный ключ, кончившиеся деньги, отклонённый текст и
    /// несуществующая модель от повтора не исправятся, а лишние попытки только приближают лимит частоты.
    public var isRetryable: Bool {
        switch self {
        case .unauthorized, .insufficientCredits, .accessDenied, .contentFiltered,
             .contextTooLong, .badRequest, .unknownModel, .cancelled:
            false
        case .timedOut, .tooManyRequests, .serverError, .invalidResponse, .unknown, .network:
            true
        }
    }

    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            "401: " + L10n.errorInvalidApiKey
        case .insufficientCredits:
            "402: " + L10n.errorInsufficientCredits
        case .accessDenied:
            "403: " + L10n.errorAccessDenied
        case .contentFiltered:
            L10n.errorContentFiltered
        case .contextTooLong:
            L10n.errorContextTooLong
        case .timedOut:
            "408: " + L10n.errorTimeout
        case .tooManyRequests:
            "429: " + L10n.errorRateLimited
        case .serverError:
            "500: " + L10n.errorProviderUnavailable
        case .cancelled:
            L10n.errorCancelled
        case let .badRequest(msg):
            L10n.errorProviderRejectedRequest + ": " + msg
        case let .invalidResponse(msg):
            L10n.errorParsing + ": " + msg
        case let .unknownModel(model):
            L10n.errorUnknownModel + ": " + model
        case let .unknown(code):
            "Unknown error (code: \(code))"
        case let .network(error):
            L10n.errorNetwork + ": " + error.localizedDescription
        }
    }

    public static func == (lhs: LLMAPIClientError, rhs: LLMAPIClientError) -> Bool {
        switch (lhs, rhs) {
        case (.unauthorized, .unauthorized): true
        case (.insufficientCredits, .insufficientCredits): true
        case (.accessDenied, .accessDenied): true
        case (.contentFiltered, .contentFiltered): true
        case (.contextTooLong, .contextTooLong): true
        case (.timedOut, .timedOut): true
        case (.tooManyRequests, .tooManyRequests): true
        case (.serverError, .serverError): true
        case (.cancelled, .cancelled): true
        case let (.badRequest(a), .badRequest(b)): a == b
        case let (.invalidResponse(a), .invalidResponse(b)): a == b
        case let (.unknownModel(a), .unknownModel(b)): a == b
        case let (.unknown(a), .unknown(b)): a == b
        case (.network, .network): true // сравниваем только тип
        default: false
        }
    }
}
