import Common
import Nimble
@testable import ShareExtension
import XCTest

/// Тесты для LLMAPIClient
public final class LLMAPIClientTests: XCTestCase {
    override public func setUp() {
        super.setUp()
        // Сбросить состояние URLProtocolStub перед каждым тестом
        URLProtocolStub.reset()
    }

    override public func tearDown() {
        // Сбросить состояние URLProtocolStub после каждого теста
        URLProtocolStub.reset()
        super.tearDown()
    }

    /// Проверяет успешный ответ OpenAI
    public func test_successfulResponse_returnsResult() async throws {
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
        // Act
        let result = try await client.send(text: "Hello", promptTemplate: "Translate: {text}", apiKey: "sk-test-key")
        // Assert
        expect(result) == expectedText
    }

    public func test_unauthorized_returns401Error() async throws {
        // Arrange: Подготовить LLMAPIClient с мок-сессией, вернуть 401
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: config)
        let client = LLMAPIClient(session: session)
        let responseJSON = Data(
            """
            { "error": { "message": "Unauthorized", "type": "invalid_api_key" } }
            """.utf8)
        URLProtocolStub.data = responseJSON
        URLProtocolStub.response = HTTPURLResponse(url: URL(string: "https://api.openai.com/v1/chat/completions")!, statusCode: 401, httpVersion: nil, headerFields: nil)
        URLProtocolStub.error = nil
        // Act & Assert
        do {
            _ = try await client.send(text: "Hello", promptTemplate: "Translate: {text}", apiKey: "sk-invalid-key")
            fail("Expected error for 401, but got success")
        } catch {
            expect(error.localizedDescription).to(satisfyAnyOf(
                contain("401"),
                contain("unauthorized"),
                contain("Unauthorized")
            ))
        }
    }

    public func test_tooManyRequests_retriesAndFails() async throws {
        // Arrange: Подготовить LLMAPIClient с мок-сессией, вернуть 429
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: config)
        let client = LLMAPIClient(session: session)
        let responseJSON = Data(
            """
            { "error": { "message": "Too Many Requests", "type": "rate_limit_reached" } }
            """.utf8)
        URLProtocolStub.data = responseJSON
        URLProtocolStub.response = HTTPURLResponse(url: URL(string: "https://api.openai.com/v1/chat/completions")!, statusCode: 429, httpVersion: nil, headerFields: nil)
        URLProtocolStub.error = nil
        // Act & Assert
        do {
            _ = try await client.send(text: "Hello", promptTemplate: "Translate: {text}", apiKey: "sk-test-key")
            fail("Expected error for 429, but got success")
        } catch {
            expect(error.localizedDescription).to(satisfyAnyOf(
                contain("429"),
                contain("too many requests"),
                contain("Too Many Requests")
            ))
        }
    }

    public func test_serverError_returns500Error() async throws {
        // Arrange: Подготовить LLMAPIClient с мок-сессией, вернуть 500
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: config)
        let client = LLMAPIClient(session: session)
        let responseJSON = Data(
            """
            { "error": { "message": "Internal Server Error", "type": "server_error" } }
            """.utf8)
        URLProtocolStub.data = responseJSON
        URLProtocolStub.response = HTTPURLResponse(url: URL(string: "https://api.openai.com/v1/chat/completions")!, statusCode: 500, httpVersion: nil, headerFields: nil)
        URLProtocolStub.error = nil
        // Act & Assert
        do {
            _ = try await client.send(text: "Hello", promptTemplate: "Translate: {text}", apiKey: "sk-test-key")
            fail("Expected error for 500, but got success")
        } catch {
            expect(error.localizedDescription).to(satisfyAnyOf(
                contain("500"),
                contain("internal server error"),
                contain("Internal Server Error")
            ))
        }
    }

    public func test_cancel_cancelsRequest() async throws {
        // Arrange: Подготовить LLMAPIClient с мок-сессией, вернуть ошибку отмены
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: config)
        let client = LLMAPIClient(session: session)
        URLProtocolStub.data = nil
        URLProtocolStub.response = nil
        URLProtocolStub.error = URLError(.cancelled)
        // Act & Assert
        do {
            _ = try await client.send(text: "Hello", promptTemplate: "Translate: {text}", apiKey: "sk-test-key")
            fail("Expected LLMAPIClientError.cancelled, but got success")
        } catch let error as LLMAPIClientError {
            expect(error) == .cancelled
        } catch {
            fail("Expected LLMAPIClientError.cancelled, got: \(error)")
        }
    }
}
