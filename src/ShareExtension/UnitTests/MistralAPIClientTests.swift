import XCTest

public final class MistralAPIClientTests: XCTestCase {
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
        let client = MistralAPIClient(session: session)
        let expectedText = "Processed text"
        let responseJSON = Data("""
        { "choices": [ { "message": { "content": "Processed text" } } ] }
        """.utf8)
        URLProtocolStub.data = responseJSON
        URLProtocolStub.response = HTTPURLResponse(url: URL(string: "https://api.mistral.ai/v1/chat/completions")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        URLProtocolStub.error = nil
        let messages = [
            LLMMessage(role: .system, content: "Do something"),
            LLMMessage(role: .user, content: "Hello")
        ]
        let result = try await client.send(messages: messages, apiKey: "sk-test")
        XCTAssertEqual(result, expectedText)
    }
}
