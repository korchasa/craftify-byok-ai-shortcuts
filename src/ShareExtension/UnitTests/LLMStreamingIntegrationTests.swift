import XCTest

/// Потоковые запросы клиентов провайдеров целиком, через подменённую сеть
public final class LLMStreamingIntegrationTests: XCTestCase {
    private let messages = [
        LLMMessage(role: .system, content: "Explain"),
        LLMMessage(role: .user, content: "Nocebo")
    ]

    override public func setUp() {
        super.setUp()
        URLProtocolStub.reset()
    }

    override public func tearDown() {
        URLProtocolStub.reset()
        super.tearDown()
    }

    private func stubbedSession(status: Int, body: String, url: String) throws -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        URLProtocolStub.data = Data(body.utf8)
        URLProtocolStub.response = try HTTPURLResponse(
            url: XCTUnwrap(URL(string: url)),
            statusCode: status,
            httpVersion: nil,
            headerFields: ["Content-Type": "text/event-stream"]
        )
        return URLSession(configuration: config)
    }

    private func collect(_ stream: AsyncThrowingStream<String, Error>) async throws -> [String] {
        var pieces: [String] = []
        for try await piece in stream {
            pieces.append(piece)
        }
        return pieces
    }

    /// Тело запроса читается из потока, если URLSession переложил его туда
    private static func body(of request: URLRequest?) -> [String: Any]? {
        guard let request else { return nil }
        var data = request.httpBody
        if data == nil, let stream = request.httpBodyStream {
            var buffer = Data()
            var chunk = [UInt8](repeating: 0, count: 4096)
            stream.open()
            defer { stream.close() }
            while stream.hasBytesAvailable {
                let read = stream.read(&chunk, maxLength: chunk.count)
                guard read > 0 else { break }
                buffer.append(chunk, count: read)
            }
            data = buffer
        }
        guard let data else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    public func test_openAI_stream_sendsStreamFlagAndJoinsChunks() async throws {
        let body = """
        : keep-alive

        data: {"choices":[{"delta":{"role":"assistant","content":""}}]}

        data: {"choices":[{"delta":{"content":"Hello"}}]}

        data: {"choices":[{"delta":{"content":" world"}}]}

        data: {"choices":[{"delta":{},"finish_reason":"stop"}]}

        data: [DONE]

        """
        let session = try stubbedSession(status: 200, body: body, url: "https://api.openai.com/v1/chat/completions")
        var captured: URLRequest?
        URLProtocolStub.requestObserver = { captured = $0 }

        let pieces = try await collect(OpenAIAPIClient(session: session).stream(messages: messages, apiKey: "sk-test"))

        XCTAssertEqual(pieces.joined(), "Hello world")
        XCTAssertEqual(pieces.count, 2)
        let sent = Self.body(of: captured)
        XCTAssertEqual(sent?["stream"] as? Bool, true)
        XCTAssertEqual((sent?["messages"] as? [[String: Any]])?.count, 2)
        XCTAssertEqual(captured?.value(forHTTPHeaderField: "Authorization"), "Bearer sk-test")
    }

    public func test_claude_stream_joinsTextDeltas() async throws {
        let body = """
        event: message_start
        data: {"type":"message_start","message":{"id":"msg_1","content":[]}}

        event: content_block_start
        data: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}

        event: ping
        data: {"type":"ping"}

        event: content_block_delta
        data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hello"}}

        event: content_block_delta
        data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":" world"}}

        event: content_block_stop
        data: {"type":"content_block_stop","index":0}

        event: message_stop
        data: {"type":"message_stop"}

        """
        let session = try stubbedSession(status: 200, body: body, url: "https://api.anthropic.com/v1/messages")
        var captured: URLRequest?
        URLProtocolStub.requestObserver = { captured = $0 }

        let pieces = try await collect(ClaudeAPIClient(session: session).stream(messages: messages, apiKey: "sk-ant-test"))

        XCTAssertEqual(pieces.joined(), "Hello world")
        let sent = Self.body(of: captured)
        XCTAssertEqual(sent?["stream"] as? Bool, true)
        XCTAssertEqual(sent?["system"] as? String, "Explain")
        XCTAssertEqual(captured?.value(forHTTPHeaderField: "x-api-key"), "sk-ant-test")
    }

    /// Отказ до начала ответа сопоставляется так же, как у обычного запроса
    public func test_stream_httpError_isMapped() async throws {
        let session = try stubbedSession(
            status: 401,
            body: #"{"error":{"message":"Incorrect API key provided","type":"invalid_request_error"}}"#,
            url: "https://api.mistral.ai/v1/chat/completions"
        )

        do {
            _ = try await collect(MistralAPIClient(session: session).stream(messages: messages, apiKey: "bad"))
            XCTFail("a rejected key must throw")
        } catch {
            XCTAssertEqual(error as? LLMAPIClientError, .unauthorized)
        }
    }
}
