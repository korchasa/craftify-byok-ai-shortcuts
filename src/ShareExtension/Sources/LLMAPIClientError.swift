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

    public var errorDescription: String? {
        switch self {
        case .unauthorized: "401 Unauthorized: неверный или отсутствующий API-ключ"
        case .tooManyRequests: "429 Too Many Requests: превышен лимит запросов"
        case .serverError: "500 Internal Server Error: внутренняя ошибка сервера"
        case .cancelled: "Операция отменена"
        case let .invalidResponse(msg): "Ошибка парсинга ответа: \(msg)"
        case let .unknown(code): "Неизвестная ошибка (код \(code))"
        case let .network(err): "Сетевая ошибка: \(err.localizedDescription)"
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
