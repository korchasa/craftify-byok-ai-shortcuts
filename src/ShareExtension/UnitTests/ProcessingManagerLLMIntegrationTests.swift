// import ShareExtension

import XCTest

/// Интеграционные тесты: OperationType → InventoryOperation → ProcessingManager → LLMAPIClient
final class ProcessingManagerLLMIntegrationTests: XCTestCase {
    override func setUp() {
        super.setUp()
        URLProtocolStub.reset()
    }

    override func tearDown() {
        URLProtocolStub.reset()
        super.tearDown()
    }

    private func makeProcessingManager() -> ProcessingManager {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: config)
        let llm = OpenAIAPIClient(session: session)
        let log = LogManagerSharedInMemory()
        let auth = AuthManagerStub(key: "sk-test-key")
        return ProcessingManager(llmClient: llm, logManager: log, authManager: auth)
    }

    func test_translateOperation_success() async throws {
        let manager = makeProcessingManager()
        let input = OperationInput(targetLanguage: "ru")
        let op = try XCTUnwrap(TranslateOperation().makeInventoryOperation(input: input, colorHex: "3288bd"))
        let expected = "Переведённый текст"
        URLProtocolStub.data = Data("""
        { "choices": [ { "message": { "content": "Переведённый текст" } } ] }
        """.utf8)
        URLProtocolStub.response = try HTTPURLResponse(url: XCTUnwrap(URL(string: "https://api.openai.com/v1/chat/completions")), statusCode: 200, httpVersion: nil, headerFields: nil)
        URLProtocolStub.error = nil
        let exp = expectation(description: "Ожидание ответа LLM")
        manager.process(text: "Hello", operation: op) { result in
            XCTAssertEqual(try? result.get(), expected)
            exp.fulfill()
        }
        await fulfillment(of: [exp], timeout: 1)
    }

    func test_simplifyOperation_success() async throws {
        let manager = makeProcessingManager()
        let input = OperationInput()
        let op = try XCTUnwrap(SimplifyOperation().makeInventoryOperation(input: input, colorHex: "fdae61"))
        let expected = "Упрощённый текст"
        URLProtocolStub.data = Data("""
        { "choices": [ { "message": { "content": "Упрощённый текст" } } ] }
        """.utf8)
        URLProtocolStub.response = try HTTPURLResponse(url: XCTUnwrap(URL(string: "https://api.openai.com/v1/chat/completions")), statusCode: 200, httpVersion: nil, headerFields: nil)
        URLProtocolStub.error = nil
        let exp = expectation(description: "Ожидание ответа LLM")
        manager.process(text: "Quantum mechanics...", operation: op) { result in
            XCTAssertEqual(try? result.get(), expected)
            exp.fulfill()
        }
        await fulfillment(of: [exp], timeout: 1)
    }

    func test_correctOperation_success() async throws {
        let manager = makeProcessingManager()
        let input = OperationInput()
        let op = try XCTUnwrap(CorrectOperation().makeInventoryOperation(input: input, colorHex: "d53e4f"))
        let expected = "Исправленный текст"
        URLProtocolStub.data = Data("""
        { "choices": [ { "message": { "content": "Исправленный текст" } } ] }
        """.utf8)
        URLProtocolStub.response = try HTTPURLResponse(url: XCTUnwrap(URL(string: "https://api.openai.com/v1/chat/completions")), statusCode: 200, httpVersion: nil, headerFields: nil)
        URLProtocolStub.error = nil
        let exp = expectation(description: "Ожидание ответа LLM")
        manager.process(text: "This are errors in text.", operation: op) { result in
            XCTAssertEqual(try? result.get(), expected)
            exp.fulfill()
        }
        await fulfillment(of: [exp], timeout: 1)
    }

    func test_explainOperation_success() async throws {
        let manager = makeProcessingManager()
        let input = OperationInput()
        let op = try XCTUnwrap(ExplainOperation().makeInventoryOperation(input: input, colorHex: "abdda4"))
        let expected = "Объяснение для эксперта"
        URLProtocolStub.data = Data("""
        { "choices": [ { "message": { "content": "Объяснение для эксперта" } } ] }
        """.utf8)
        URLProtocolStub.response = try HTTPURLResponse(url: XCTUnwrap(URL(string: "https://api.openai.com/v1/chat/completions")), statusCode: 200, httpVersion: nil, headerFields: nil)
        URLProtocolStub.error = nil
        let exp = expectation(description: "Ожидание ответа LLM")
        manager.process(text: "Photosynthesis", operation: op) { result in
            XCTAssertEqual(try? result.get(), expected)
            exp.fulfill()
        }
        await fulfillment(of: [exp], timeout: 1)
    }

    func test_llm_error_returnsFailure() async throws {
        let manager = makeProcessingManager()
        let input = OperationInput(targetLanguage: "ru")
        let op = try XCTUnwrap(TranslateOperation().makeInventoryOperation(input: input, colorHex: "3288bd"))
        URLProtocolStub.data = "{}".data(using: .utf8)
        URLProtocolStub.response = try HTTPURLResponse(url: XCTUnwrap(URL(string: "https://api.openai.com/v1/chat/completions")), statusCode: 500, httpVersion: nil, headerFields: nil)
        URLProtocolStub.error = nil
        let exp = expectation(description: "Ожидание ошибки LLM")
        manager.process(text: "Hello", operation: op) { result in
            switch result {
            case let .failure(error):
                // Проверяем, что получили ошибку сервера (код 500)
                let description = error.localizedDescription.lowercased()
                XCTAssertTrue(description.contains("500"))
            case .success:
                XCTFail("Ожидалась ошибка, но получен успех")
            }
            exp.fulfill()
        }
        await fulfillment(of: [exp], timeout: 8.0)
    }

    func test_llm_unauthorized_returnsFailure() async throws {
        let manager = makeProcessingManager()
        let input = OperationInput(targetLanguage: "ru")
        let op = try XCTUnwrap(TranslateOperation().makeInventoryOperation(input: input, colorHex: "3288bd"))
        let responseJSON = Data("""
        { "error": { "message": "Unauthorized", "type": "invalid_api_key" } }
        """.utf8)
        URLProtocolStub.data = responseJSON
        URLProtocolStub.response = try HTTPURLResponse(
            url: XCTUnwrap(URL(string: "https://api.openai.com/v1/chat/completions")),
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )
        URLProtocolStub.error = nil
        let exp = expectation(description: "Ожидание ошибки Unauthorized")
        manager.process(text: "Hello", operation: op) { result in
            switch result {
            case let .failure(error):
                let desc = error.localizedDescription.lowercased()
                XCTAssertTrue(desc.contains("401"))
            case .success:
                XCTFail("Ожидалась ошибка, но получен успех")
            }
            exp.fulfill()
        }
        await fulfillment(of: [exp], timeout: 8.0)
    }

    func test_llm_tooManyRequests_returnsFailureAfterRetries() async throws {
        let manager = makeProcessingManager()
        let input = OperationInput(targetLanguage: "ru")
        let op = try XCTUnwrap(TranslateOperation().makeInventoryOperation(input: input, colorHex: "3288bd"))
        let responseJSON = Data("""
        { "error": { "message": "Too Many Requests", "type": "rate_limit_reached" } }
        """.utf8)
        URLProtocolStub.data = responseJSON
        URLProtocolStub.response = try HTTPURLResponse(
            url: XCTUnwrap(URL(string: "https://api.openai.com/v1/chat/completions")),
            statusCode: 429,
            httpVersion: nil,
            headerFields: nil
        )
        URLProtocolStub.error = nil
        let exp = expectation(description: "Ожидание ошибки Too Many Requests")
        manager.process(text: "Hello", operation: op) { result in
            switch result {
            case let .failure(error):
                let desc = error.localizedDescription.lowercased()
                XCTAssertTrue(desc.contains("429"))
            case .success:
                XCTFail("Ожидалась ошибка, но получен успех")
            }
            exp.fulfill()
        }
        await fulfillment(of: [exp], timeout: 8.0)
    }

    func test_llm_invalidResponse_returnsFailure() async throws {
        let manager = makeProcessingManager()
        let input = OperationInput(targetLanguage: "ru")
        let op = try XCTUnwrap(TranslateOperation().makeInventoryOperation(input: input, colorHex: "3288bd"))
        URLProtocolStub.data = "{}".data(using: .utf8)
        URLProtocolStub.response = try HTTPURLResponse(
            url: XCTUnwrap(URL(string: "https://api.openai.com/v1/chat/completions")),
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        URLProtocolStub.error = nil
        let exp = expectation(description: "Ожидание ошибки invalidResponse")
        manager.process(text: "Hello", operation: op) { result in
            switch result {
            case let .failure(error):
                if let llmError = error as? LLMAPIClientError {
                    switch llmError {
                    case .invalidResponse:
                        XCTAssertTrue(true)
                    default:
                        XCTFail("Ожидался LLMAPIClientError.invalidResponse, получено: \(llmError)")
                    }
                } else {
                    XCTFail("Ожидался LLMAPIClientError.invalidResponse, получено: \(error)")
                }
            case .success:
                XCTFail("Ожидалась ошибка, но получен успех")
            }
            exp.fulfill()
        }
        await fulfillment(of: [exp], timeout: 8.0)
    }
}
