import XCTest

/// Разбор отдельных событий потокового ответа: формат чата OpenAI (его же используют Mistral
/// и OpenRouter) и типизированные события Claude
public final class LLMStreamParsingTests: XCTestCase {
    private let model = "test-model"

    public func testOpenAIChunksYieldTextUntilDone() throws {
        let role = #"{"choices":[{"index":0,"delta":{"role":"assistant","content":""}}]}"#
        let first = #"{"choices":[{"index":0,"delta":{"content":"Hel"}}]}"#
        let second = #"{"choices":[{"index":0,"delta":{"content":"lo"}}]}"#
        let finish = #"{"choices":[{"index":0,"delta":{},"finish_reason":"stop"}]}"#
        let usage = #"{"choices":[],"usage":{"prompt_tokens":3,"completion_tokens":2}}"#

        XCTAssertEqual(try LLMStreamParsing.openAIChatPiece(data: role, model: model), .skip)
        XCTAssertEqual(try LLMStreamParsing.openAIChatPiece(data: first, model: model), .text("Hel"))
        XCTAssertEqual(try LLMStreamParsing.openAIChatPiece(data: second, model: model), .text("lo"))
        XCTAssertEqual(try LLMStreamParsing.openAIChatPiece(data: finish, model: model), .skip)
        XCTAssertEqual(try LLMStreamParsing.openAIChatPiece(data: usage, model: model), .skip)
        XCTAssertEqual(try LLMStreamParsing.openAIChatPiece(data: "[DONE]", model: model), .done)
    }

    public func testClaudeDeltasYieldTextUntilStop() throws {
        let start = #"{"type":"message_start","message":{"id":"msg_1","content":[]}}"#
        let blockStart = #"{"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}"#
        let delta = #"{"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hi"}}"#
        let thinking = #"{"type":"content_block_delta","index":0,"delta":{"type":"thinking_delta","thinking":"hmm"}}"#

        XCTAssertEqual(try LLMStreamParsing.claudePiece(event: "message_start", data: start, model: model), .skip)
        XCTAssertEqual(try LLMStreamParsing.claudePiece(event: "content_block_start", data: blockStart, model: model), .skip)
        XCTAssertEqual(try LLMStreamParsing.claudePiece(event: "ping", data: #"{"type":"ping"}"#, model: model), .skip)
        XCTAssertEqual(try LLMStreamParsing.claudePiece(event: "content_block_delta", data: delta, model: model), .text("Hi"))
        XCTAssertEqual(try LLMStreamParsing.claudePiece(event: "content_block_delta", data: thinking, model: model), .skip)
        XCTAssertEqual(try LLMStreamParsing.claudePiece(event: "message_stop", data: #"{"type":"message_stop"}"#, model: model), .done)
    }

    /// Ошибка, пришедшая посреди ответа, становится той же ошибкой провайдера, что и при отказе
    /// в начале: у пользователя тот же понятный совет
    public func testErrorInsideTheStreamIsThrown() {
        let openRouterError = #"{"error":{"message":"Rate limit exceeded","code":429}}"#
        XCTAssertThrowsError(try LLMStreamParsing.openAIChatPiece(data: openRouterError, model: model)) { error in
            XCTAssertEqual(error as? LLMAPIClientError, .tooManyRequests)
        }

        let overloaded = #"{"type":"error","error":{"type":"overloaded_error","message":"Overloaded"}}"#
        XCTAssertThrowsError(try LLMStreamParsing.claudePiece(event: "error", data: overloaded, model: model)) { error in
            XCTAssertEqual(error as? LLMAPIClientError, .serverError)
        }
    }
}
