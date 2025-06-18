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
        URLProtocolStub.response = HTTPURLResponse(url: URL(string: "https://openrouter.ai/api/v1/chat/completions")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        URLProtocolStub.error = nil
        let result = try await client.send(text: "Hello", promptTemplate: "Translate: {text}", apiKey: "sk-test")
        XCTAssertEqual(result, expectedText)
    }
}
