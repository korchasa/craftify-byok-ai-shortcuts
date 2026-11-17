import Foundation

// [REF:fr:ux.streaming]
/// Разбор событий потокового ответа (server-sent events) у провайдеров. Функции чистые:
/// на вход — поле `data:` одного события, на выход — кусок текста, конец или пропуск.
/// Ошибку провайдера посреди ответа они превращают в ту же `LLMAPIClientError`,
/// что и отказ в начале запроса.
public enum LLMStreamParsing {
    /// Маркер конца потока в формате чата OpenAI
    private static let openAIDoneMarker = "[DONE]"

    private static let httpBadRequest = 400
    private static let httpUnauthorized = 401
    private static let httpPaymentRequired = 402
    private static let httpForbidden = 403
    private static let httpNotFound = 404
    private static let httpPayloadTooLarge = 413
    private static let httpTooManyRequests = 429
    private static let httpServerError = 500
    private static let httpGatewayTimeout = 504
    /// Код, которым Claude отвечает на перегрузку
    private static let httpOverloaded = 529

    /// HTTP-коды, которым соответствуют типы ошибок Claude, — по ним ошибка из потока
    /// получает тот же разбор, что и ответ с этим кодом
    private static let claudeErrorStatus: [String: Int] = [
        "invalid_request_error": httpBadRequest,
        "authentication_error": httpUnauthorized,
        "billing_error": httpPaymentRequired,
        "permission_error": httpForbidden,
        "not_found_error": httpNotFound,
        "request_too_large": httpPayloadTooLarge,
        "rate_limit_error": httpTooManyRequests,
        "api_error": httpServerError,
        "timeout_error": httpGatewayTimeout,
        "overloaded_error": httpOverloaded
    ]

    /// Код для ошибки Claude неизвестного типа: отказ запроса
    private static let claudeUnknownErrorStatus = httpBadRequest

    /// Событие формата чата OpenAI; так же стримят Mistral и OpenRouter
    /// - Parameters:
    ///   - data: Содержимое поля `data:` события
    ///   - model: Запрошенная модель — для сообщения о недоступной модели
    /// - Returns: Кусок текста, конец потока или пропуск
    /// - Throws: `LLMAPIClientError`, если событие несёт ошибку провайдера
    public static func openAIChatPiece(data: String, model: String) throws -> LLMStreamPiece {
        if data == openAIDoneMarker {
            return .done
        }
        let bytes = Data(data.utf8)
        if let error = LLMHTTPErrorMapper.errorInSuccessBody(data: bytes, model: model) {
            throw error
        }
        guard let json = try? JSONSerialization.jsonObject(with: bytes) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let delta = choices.first?["delta"] as? [String: Any],
              let content = delta["content"] as? String,
              !content.isEmpty
        else {
            return .skip
        }
        return .text(content)
    }

    /// Событие потока Claude
    /// - Parameters:
    ///   - event: Значение поля `event:`, если оно было
    ///   - data: Содержимое поля `data:` события
    ///   - model: Запрошенная модель — для сообщения о недоступной модели
    /// - Returns: Кусок текста, конец потока или пропуск
    /// - Throws: `LLMAPIClientError`, если событие несёт ошибку провайдера
    public static func claudePiece(event: String?, data: String, model: String) throws -> LLMStreamPiece {
        let bytes = Data(data.utf8)
        let json = (try? JSONSerialization.jsonObject(with: bytes) as? [String: Any]) ?? [:]
        let type = (json["type"] as? String) ?? event
        switch type {
        case "message_stop":
            return .done
        case "error":
            let errorType = (json["error"] as? [String: Any])?["type"] as? String ?? ""
            let status = claudeErrorStatus[errorType] ?? claudeUnknownErrorStatus
            throw LLMHTTPErrorMapper.error(statusCode: status, data: bytes, model: model)
        case "content_block_delta":
            guard let delta = json["delta"] as? [String: Any],
                  delta["type"] as? String == "text_delta",
                  let text = delta["text"] as? String,
                  !text.isEmpty
            else {
                return .skip
            }
            return .text(text)
        default:
            return .skip
        }
    }
}
