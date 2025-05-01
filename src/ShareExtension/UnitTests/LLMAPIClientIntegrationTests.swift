import Common
import Nimble
@testable import ShareExtension
import XCTest

/// Интеграционные тесты для LLMAPIClient (end-to-end через URLProtocolStub)
public final class LLMAPIClientIntegrationTests: XCTestCase {
    override public func setUp() {
        super.setUp()
        URLProtocolStub.reset()
    }

    override public func tearDown() {
        URLProtocolStub.reset()
        super.tearDown()
    }

    /// Проверяет, что отправляется корректный запрос и парсится успешный ответ
    public func test_send_successfulRequest_sendsCorrectBodyAndHeaders_andParsesResult() async throws {
        // Arrange
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: config)
        let client = LLMAPIClient(session: session)
        let expectedText = "Processed text"
        let responseJSON = Data(
            """
            { "choices": [ { "message": { "content": "Processed text" } } ] }
            """.utf8)
        URLProtocolStub.data = responseJSON
        URLProtocolStub.response = HTTPURLResponse(url: URL(string: "https://api.openai.com/v1/chat/completions")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        URLProtocolStub.error = nil
        var capturedRequest: URLRequest?
        URLProtocolStub.requestObserver = { request in
            capturedRequest = request
        }
        // Act
        let result = try await client.send(text: "Hello integration", promptTemplate: "Translate: {text}", apiKey: "sk-integration-key")
        // Assert
        expect(result) == expectedText
        expect(capturedRequest).notTo(beNil())
        if let request = capturedRequest {
            expect(request.url?.absoluteString) == "https://api.openai.com/v1/chat/completions"
            expect(request.httpMethod) == "POST"
            expect(request.value(forHTTPHeaderField: "Authorization")) == "Bearer sk-integration-key"
            expect(request.value(forHTTPHeaderField: "Content-Type")) == "application/json"
            var bodyData: Data? = request.httpBody
            if bodyData == nil, let stream = request.httpBodyStream {
                var buffer = Data()
                let chunkSize = 4096
                var temp = [UInt8](repeating: 0, count: chunkSize)
                stream.open()
                defer { stream.close() }
                while stream.hasBytesAvailable {
                    let read = stream.read(&temp, maxLength: chunkSize)
                    if read > 0 {
                        buffer.append(temp, count: read)
                    } else {
                        break
                    }
                }
                if !buffer.isEmpty { bodyData = buffer }
            }
            guard let httpBody = bodyData else {
                fail("httpBody и httpBodyStream отсутствуют в capturedRequest — не отправляется тело JSON")
                return
            }
            let body = try JSONSerialization.jsonObject(with: httpBody) as? [String: Any]
            expect(body?["model"] as? String) == "gpt-4o-mini"
            expect(body?["temperature"] as? Double) == 0.7
            expect(body?["max_tokens"] as? Int) == 2048
            let messages = body?["messages"] as? [[String: Any]]
            expect(messages?.count) == 2
            expect(messages?.first? ["role"] as? String) == "system"
            expect(messages?.first? ["content"] as? String) == "Translate: {text}"
            expect(messages?.last? ["role"] as? String) == "user"
            expect(messages?.last? ["content"] as? String) == "Hello integration"
        }
    }
}
