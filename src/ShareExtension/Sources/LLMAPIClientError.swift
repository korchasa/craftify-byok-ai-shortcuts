import Foundation

/// Ошибки клиента LLMAPIClient для OpenAI API
public enum LLMAPIClientError: Error, LocalizedError, Equatable {
    case unauthorized
    case tooManyRequests
    case serverError
    case cancelled
    case invalidResponse(String)
    case unknown(Int)
    case network(Error)

    public var userFacingError: UserFacingError {
        switch self {
        case .unauthorized:
            UserFacingError(
                messageKey: .errorInvalidApiKey,
                adviceKey: .adviceCheckApiKey
            )
        case .tooManyRequests:
            UserFacingError(
                messageKey: .errorNetwork,
                adviceKey: .adviceTryAgainLater
            )
        case .serverError:
            UserFacingError(
                messageKey: .errorProcessing,
                adviceKey: .adviceTryAgainLater
            )
        case .cancelled:
            UserFacingError(
                messageKey: .errorCancelled,
                adviceKey: .adviceTryAgainLater
            )
        case .invalidResponse:
            UserFacingError(
                messageKey: .errorParsing,
                adviceKey: .adviceTryAgainLater
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

    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            "401: " + NSLocalizedString("error_invalid_api_key", bundle: .main, comment: "")
        case .tooManyRequests:
            "429: " + NSLocalizedString("error_network", bundle: .main, comment: "")
        case .serverError:
            "500: " + NSLocalizedString("error_processing", bundle: .main, comment: "")
        case .cancelled:
            NSLocalizedString("error_cancelled", bundle: .main, comment: "")
        case let .invalidResponse(msg):
            NSLocalizedString("error_parsing", bundle: .main, comment: "") + ": " + msg
        case let .unknown(code):
            "Unknown error (code: \(code))"
        case let .network(error):
            NSLocalizedString("error_network", bundle: .main, comment: "") + ": " + error.localizedDescription
        }
    }

    public static func == (lhs: LLMAPIClientError, rhs: LLMAPIClientError) -> Bool {
        switch (lhs, rhs) {
        case (.unauthorized, .unauthorized): true
        case (.tooManyRequests, .tooManyRequests): true
        case (.serverError, .serverError): true
        case (.cancelled, .cancelled): true
        case let (.invalidResponse(a), .invalidResponse(b)): a == b
        case let (.unknown(a), .unknown(b)): a == b
        case (.network, .network): true // сравниваем только тип
        default: false
        }
    }
}
