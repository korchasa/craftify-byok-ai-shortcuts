import Foundation

/// Единый разбор ответов об ошибке для всех провайдеров.
///
/// Тела различаются деталями, но устроены одинаково: объект `error` с текстом и признаком вида
/// ошибки. OpenAI и Mistral кладут признак в `code`, Claude — в `type`, OpenRouter дублирует
/// в `code` числовой HTTP-код, а причину модерации выносит в `metadata`. Поэтому признак ищем
/// сразу во всех этих полях, а решение принимаем по HTTP-коду с уточнением по тексту.
///
/// Соответствия проверены по документации провайдеров (август 2026):
/// platform.claude.com/docs/en/api/errors, developers.openai.com/api/docs/guides/error-codes,
/// openrouter.ai/docs/api-reference/errors, docs.mistral.ai/resources/error-glossary.
public enum LLMHTTPErrorMapper {
    private static let httpUnauthorized = 401
    private static let httpPaymentRequired = 402
    private static let httpForbidden = 403
    private static let httpNotFound = 404
    private static let httpRequestTimeout = 408
    private static let httpPayloadTooLarge = 413
    private static let httpTooManyRequests = 429
    private static let httpGatewayTimeout = 504
    private static let httpClientErrorLowerBound = 400
    private static let httpServerErrorLowerBound = 500
    private static let httpServerErrorUpperBound = 600
    /// Ошибка в теле успешного ответа приходит без своего HTTP-кода — разбираем её как отказ запроса
    private static let assumedCodeForBodyError = 400

    /// Кончились деньги или квота: провайдеры сообщают об этом и через 402, и через 429
    private static let creditMarkers = [
        "insufficient_quota",
        "credit_balance_exhausted",
        "organization_spend_limit_exceeded",
        "project_spend_limit_exceeded",
        "organization_usage_limit_exceeded",
        "billing_error",
        "insufficient credits",
        "insufficient balance",
        "quota",
        "billing"
    ]
    /// Текст не помещается в контекст модели либо запрос слишком велик целиком
    private static let contextMarkers = [
        "context_length_exceeded",
        "request_too_large",
        "string_above_max_length",
        "context length",
        "context window",
        "maximum context",
        "too many tokens",
        "prompt is too long"
    ]
    /// Модель не найдена или недоступна ключу
    private static let modelMarkers = [
        "model_not_found",
        "invalid_model",
        "not a valid model id",
        "unknown model",
        "invalid model",
        "model does not exist",
        "does not exist or you do not have access"
    ]
    /// Запрос отклонён фильтром безопасности провайдера
    private static let moderationMarkers = [
        "content_filter",
        "content_policy",
        "moderation",
        "guardrail",
        "flagged",
        "safety"
    ]

    /// Признаки ответа, разобранные из тела
    private struct ProviderResponse {
        /// Сообщение провайдера — единственный источник подробностей для нераспознанных отказов
        let message: String?
        /// Сообщение вместе с полями типа и кода в нижнем регистре: по нему ищем признаки
        let markers: String
        /// Код, который провайдер продублировал в теле (OpenRouter при ошибке в успешном ответе)
        let code: Int?
    }

    /// Классифицирует ответ об ошибке по HTTP-коду и телу.
    /// - Parameters:
    ///   - statusCode: HTTP-код ответа.
    ///   - data: тело ответа.
    ///   - model: идентификатор запрошенной модели — попадает в ошибку о недоступной модели.
    public static func error(statusCode: Int, data: Data, model: String) -> LLMAPIClientError {
        classify(statusCode: statusCode, response: parse(data), model: model)
    }

    /// Ищет ошибку в теле ответа с кодом 200. Так отвечает OpenRouter, когда модель уже начала
    /// обработку, и так же выглядит срабатывание фильтра безопасности у OpenAI и Mistral.
    /// - Returns: `nil`, если тело не содержит признаков ошибки.
    public static func errorInSuccessBody(data: Data, model: String) -> LLMAPIClientError? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        if let choices = json["choices"] as? [[String: Any]],
           let reason = choices.first?["finish_reason"] as? String,
           contains(reason.lowercased(), moderationMarkers)
        {
            return .contentFiltered
        }
        guard json["error"] != nil else {
            return nil
        }
        let response = parse(data)
        return classify(statusCode: response.code ?? assumedCodeForBodyError, response: response, model: model)
    }

    private static func classify(statusCode: Int, response: ProviderResponse, model: String) -> LLMAPIClientError {
        // [REF:fr:ux.provider-errors]
        switch statusCode {
        case httpUnauthorized:
            return .unauthorized
        case httpPaymentRequired:
            return .insufficientCredits
        case httpForbidden:
            return contains(response.markers, moderationMarkers) ? .contentFiltered : .accessDenied
        case httpNotFound:
            return .unknownModel(model)
        case httpRequestTimeout, httpGatewayTimeout:
            return .timedOut
        case httpPayloadTooLarge:
            return .contextTooLong
        case httpTooManyRequests:
            return contains(response.markers, creditMarkers) ? .insufficientCredits : .tooManyRequests
        case httpServerErrorLowerBound ..< httpServerErrorUpperBound:
            return .serverError
        default:
            break
        }
        // Остальные отказы (400, 422 и прочие) различаются только текстом провайдера
        if contains(response.markers, contextMarkers) {
            return .contextTooLong
        }
        if contains(response.markers, modelMarkers) {
            return .unknownModel(model)
        }
        if contains(response.markers, moderationMarkers) {
            return .contentFiltered
        }
        if contains(response.markers, creditMarkers) {
            return .insufficientCredits
        }
        if let message = response.message, !message.isEmpty {
            return .badRequest(message)
        }
        // Недокументированный отказ без тела: сказать по существу нечего, но это всё же отказ
        // запроса — «провайдер отклонил запрос» подсказывает больше, чем «неизвестная ошибка»
        if (httpClientErrorLowerBound ..< httpServerErrorLowerBound).contains(statusCode) {
            return .badRequest("")
        }
        return .unknown(statusCode)
    }

    private static func parse(_ data: Data) -> ProviderResponse {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return ProviderResponse(message: nil, markers: "", code: nil)
        }
        let errorObject = json["error"] as? [String: Any]
        let message = (errorObject?["message"] as? String) ?? (json["message"] as? String) ?? validationDetail(json)
        var parts: [String] = []
        if let message {
            parts.append(message)
        }
        for key in ["type", "code"] {
            if let value = errorObject?[key] as? String {
                parts.append(value)
            }
        }
        if let metadata = errorObject?["metadata"] as? [String: Any] {
            // OpenRouter выносит причину модерации в метаданные, а сообщение оставляет общим
            if metadata["reasons"] != nil || metadata["flagged_input"] != nil {
                parts.append("moderation")
            }
            if let reasons = metadata["reasons"] as? [String] {
                parts.append(contentsOf: reasons)
            }
            if let errorType = metadata["error_type"] as? String {
                parts.append(errorType)
            }
        }
        return ProviderResponse(
            message: message,
            markers: parts.joined(separator: " ").lowercased(),
            code: errorObject?["code"] as? Int
        )
    }

    /// Mistral сообщает об ошибках проверки запроса массивом `detail`
    private static func validationDetail(_ json: [String: Any]) -> String? {
        if let detail = json["detail"] as? String {
            return detail
        }
        guard let details = json["detail"] as? [[String: Any]] else {
            return nil
        }
        let messages = details.compactMap { $0["msg"] as? String }
        return messages.isEmpty ? nil : messages.joined(separator: "; ")
    }

    private static func contains(_ haystack: String, _ markers: [String]) -> Bool {
        markers.contains { haystack.contains($0) }
    }
}
