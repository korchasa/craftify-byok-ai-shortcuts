import Foundation
import XCTest

/// Разбор реальных тел ответов всех четырёх провайдеров.
/// Формы взяты из документации (август 2026): platform.claude.com/docs/en/api/errors,
/// developers.openai.com/api/docs/guides/error-codes, openrouter.ai/docs/api-reference/errors,
/// docs.mistral.ai/resources/error-glossary.
final class LLMHTTPErrorMapperTests: XCTestCase {
    private let model = "vendor/some-model"

    private func mapped(_ statusCode: Int, _ body: String) -> LLMAPIClientError {
        LLMHTTPErrorMapper.error(statusCode: statusCode, data: Data(body.utf8), model: model)
    }

    // MARK: - OpenAI

    func test_openAI_responses() {
        XCTAssertEqual(
            mapped(401, #"{"error":{"message":"Incorrect API key provided","type":"invalid_request_error","code":"invalid_api_key"}}"#),
            .unauthorized
        )
        XCTAssertEqual(
            mapped(429, #"{"error":{"message":"You exceeded your current quota","type":"insufficient_quota","code":"insufficient_quota"}}"#),
            .insufficientCredits
        )
        XCTAssertEqual(
            mapped(429, #"{"error":{"message":"Credit balance exhausted","code":"credit_balance_exhausted"}}"#),
            .insufficientCredits
        )
        XCTAssertEqual(
            mapped(429, #"{"error":{"message":"Rate limit reached for requests","code":"rate_limit_exceeded"}}"#),
            .tooManyRequests
        )
        XCTAssertEqual(
            mapped(403, #"{"error":{"message":"Country, region, or territory not supported","code":"unsupported_country_region_territory"}}"#),
            .accessDenied
        )
        XCTAssertEqual(
            mapped(404, #"{"error":{"message":"The model does not exist","code":"model_not_found"}}"#),
            .unknownModel(model)
        )
        XCTAssertEqual(
            mapped(400, #"{"error":{"message":"This model's maximum context length is 8192 tokens","code":"context_length_exceeded"}}"#),
            .contextTooLong
        )
    }

    /// Фильтр безопасности OpenAI виден только по причине остановки в успешном ответе
    func test_openAI_contentFilterInSuccessBody() {
        let body = #"{"choices":[{"finish_reason":"content_filter","message":{"role":"assistant"}}]}"#
        XCTAssertEqual(LLMHTTPErrorMapper.errorInSuccessBody(data: Data(body.utf8), model: model), .contentFiltered)
    }

    // MARK: - Claude

    func test_claude_responses() {
        XCTAssertEqual(
            mapped(401, #"{"type":"error","error":{"type":"authentication_error","message":"invalid x-api-key"}}"#),
            .unauthorized
        )
        XCTAssertEqual(
            mapped(402, #"{"type":"error","error":{"type":"billing_error","message":"Your credit balance is too low"}}"#),
            .insufficientCredits
        )
        XCTAssertEqual(
            mapped(403, #"{"type":"error","error":{"type":"permission_error","message":"Your API key does not have permission"}}"#),
            .accessDenied
        )
        XCTAssertEqual(
            mapped(413, #"{"type":"error","error":{"type":"request_too_large","message":"Request exceeds the maximum allowed size"}}"#),
            .contextTooLong
        )
        XCTAssertEqual(
            mapped(429, #"{"type":"error","error":{"type":"rate_limit_error","message":"Number of requests has exceeded your rate limit"}}"#),
            .tooManyRequests
        )
        XCTAssertEqual(
            mapped(504, #"{"type":"error","error":{"type":"timeout_error","message":"Request timed out"}}"#),
            .timedOut
        )
        XCTAssertEqual(
            mapped(529, #"{"type":"error","error":{"type":"overloaded_error","message":"Overloaded"}}"#),
            .serverError
        )
        XCTAssertEqual(
            mapped(400, #"{"type":"error","error":{"type":"invalid_request_error","message":"This model does not support assistant message prefill."}}"#),
            .badRequest("This model does not support assistant message prefill.")
        )
    }

    // MARK: - OpenRouter

    func test_openRouter_responses() {
        XCTAssertEqual(
            mapped(402, #"{"error":{"code":402,"message":"Insufficient credits"}}"#),
            .insufficientCredits
        )
        XCTAssertEqual(
            mapped(403, #"{"error":{"code":403,"message":"Input flagged","metadata":{"reasons":["harassment"],"provider_name":"OpenAI"}}}"#),
            .contentFiltered
        )
        XCTAssertEqual(mapped(408, #"{"error":{"code":408,"message":"Request timed out"}}"#), .timedOut)
        XCTAssertEqual(mapped(502, #"{"error":{"code":502,"message":"Model is down"}}"#), .serverError)
        XCTAssertEqual(mapped(503, #"{"error":{"code":503,"message":"No available model provider"}}"#), .serverError)
        // Проба 2026-07-15: несуществующая модель приходит как 400, а не 404
        XCTAssertEqual(
            mapped(400, #"{"error":{"code":400,"message":"vendor/some-model is not a valid model ID"}}"#),
            .unknownModel(model)
        )
    }

    /// Если модель уже начала обработку, OpenRouter отвечает 200, а ошибку кладёт в тело
    func test_openRouter_errorInsideSuccessBody() {
        let body = #"{"error":{"code":402,"message":"Insufficient credits"}}"#
        XCTAssertEqual(LLMHTTPErrorMapper.errorInSuccessBody(data: Data(body.utf8), model: model), .insufficientCredits)
    }

    // MARK: - Mistral

    func test_mistral_responses() {
        XCTAssertEqual(
            mapped(401, #"{"message":"Unauthorized","request_id":"abc"}"#),
            .unauthorized
        )
        XCTAssertEqual(
            mapped(429, #"{"message":"Requests rate limit exceeded"}"#),
            .tooManyRequests
        )
        XCTAssertEqual(
            mapped(422, #"{"detail":[{"msg":"Input should be a valid string","type":"string_type"}]}"#),
            .badRequest("Input should be a valid string")
        )
    }

    // MARK: - Общие случаи

    func test_unrecognizedResponses() {
        // Недокументированный отказ без тела читается как отказ запроса, а не как «неизвестно что»
        XCTAssertEqual(mapped(418, ""), .badRequest(""))
        XCTAssertEqual(mapped(451, "not a json"), .badRequest(""))
        XCTAssertNil(LLMAPIClientError.badRequest("").providerDetail, "Пустое уточнение не должно попадать в алерт")
        // За пределами 4xx и 5xx сказать нечего — остаётся неизвестная ошибка с кодом
        XCTAssertEqual(mapped(600, ""), .unknown(600))
        // Успешное тело без признаков ошибки не должно превращаться в ошибку
        XCTAssertNil(LLMHTTPErrorMapper.errorInSuccessBody(data: Data(#"{"choices":[{"message":{"content":"ok"}}]}"#.utf8), model: model))
    }

    /// Повтор запроса осмыслен только для временных сбоев
    func test_retryability() {
        let retryable: [LLMAPIClientError] = [.tooManyRequests, .serverError, .timedOut, .invalidResponse("x"), .unknown(500), .network(URLError(.timedOut))]
        let permanent: [LLMAPIClientError] = [.unauthorized, .insufficientCredits, .accessDenied, .contentFiltered, .contextTooLong, .badRequest("x"), .unknownModel("m"), .cancelled]
        for error in retryable {
            XCTAssertTrue(error.isRetryable, "\(error) должна повторяться")
        }
        for error in permanent {
            XCTAssertFalse(error.isRetryable, "\(error) не должна повторяться")
        }
    }
}
