import XCTest

public final class OpenRouterAPIClientTests: XCTestCase {
    override public func setUp() {
        super.setUp()
        URLProtocolStub.reset()
    }

    override public func tearDown() {
        URLProtocolStub.reset()
        super.tearDown()
    }

    public func test_successfulResponse_returnsResult() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: config)
        let client = OpenRouterAPIClient(session: session)
        let expectedText = "Processed text"
        let responseJSON = Data("""
        { "choices": [ { "message": { "content": "Processed text" } } ] }
        """.utf8)
        URLProtocolStub.data = responseJSON
        URLProtocolStub.response = try HTTPURLResponse(url: XCTUnwrap(URL(string: "https://openrouter.ai/api/v1/chat/completions")), statusCode: 200, httpVersion: nil, headerFields: nil)
        URLProtocolStub.error = nil
        let messages = [
            LLMMessage(role: .system, content: "Do something"),
            LLMMessage(role: .user, content: "Hello")
        ]
        let result = try await client.send(messages: messages, apiKey: "sk-test")
        XCTAssertEqual(result, expectedText)
    }

    /// Форма ответа проверена живой пробой OpenRouter (2026-07-15):
    /// HTTP 400, {"error":{"message":"<model> is not a valid model ID","code":400}}
    public func test_unknownModelResponse_throwsUnknownModelWithoutRetry() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: config)
        let client = OpenRouterAPIClient(session: session, model: "craftify/no-such-model")
        URLProtocolStub.data = Data("""
        { "error": { "message": "craftify/no-such-model is not a valid model ID", "code": 400 }, "user_id": "user_x" }
        """.utf8)
        URLProtocolStub.response = try HTTPURLResponse(
            url: XCTUnwrap(URL(string: "https://openrouter.ai/api/v1/chat/completions")),
            statusCode: 400,
            httpVersion: nil,
            headerFields: nil
        )
        URLProtocolStub.error = nil
        let start = Date()
        do {
            _ = try await client.send(messages: [LLMMessage(role: .user, content: "Hello")], apiKey: "sk-test")
            XCTFail("Expected unknownModel error")
        } catch let error as LLMAPIClientError {
            XCTAssertEqual(error, .unknownModel("craftify/no-such-model"))
            XCTAssertEqual(error.userFacingError.messageKey, .errorUnknownModel)
            XCTAssertEqual(error.userFacingError.adviceKey, .adviceChangeModel)
        }
        // Повторы бессмысленны для несуществующей модели — ошибка должна лететь сразу,
        // без ретраев с задержками 1+2 секунды
        XCTAssertLessThan(Date().timeIntervalSince(start), 1.0)
    }
}
