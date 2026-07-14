import XCTest

/// Тесты загрузчика списка моделей: разбор ответа /v1/models и заголовки авторизации
public final class LLMModelListFetcherTests: XCTestCase {
    override public func setUp() {
        super.setUp()
        URLProtocolStub.reset()
    }

    override public func tearDown() {
        URLProtocolStub.reset()
        super.tearDown()
    }

    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: config)
    }

    public func test_fetchModels_ParsesDataArrayAndSortsIds() async throws {
        let responseJSON = Data(
            """
            { "data": [ { "id": "z-model" }, { "id": "a-model" }, { "id": "m-model" } ] }
            """.utf8
        )
        URLProtocolStub.data = responseJSON
        URLProtocolStub.response = try HTTPURLResponse(
            url: XCTUnwrap(URL(string: "https://api.openai.com/v1/models")),
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        var capturedRequest: URLRequest?
        URLProtocolStub.requestObserver = { capturedRequest = $0 }

        let fetcher = LLMModelListFetcher(session: makeSession())
        let models = try await fetcher.fetchModels(provider: .openAI, apiKey: "sk-test-key")

        XCTAssertEqual(models, ["a-model", "m-model", "z-model"])
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer sk-test-key")
        XCTAssertEqual(capturedRequest?.url?.absoluteString, "https://api.openai.com/v1/models")
    }

    public func test_fetchModels_ClaudeUsesApiKeyHeader() async throws {
        let responseJSON = Data(
            """
            { "data": [ { "id": "claude-sonnet-5" } ] }
            """.utf8
        )
        URLProtocolStub.data = responseJSON
        URLProtocolStub.response = try HTTPURLResponse(
            url: XCTUnwrap(URL(string: "https://api.anthropic.com/v1/models")),
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        var capturedRequest: URLRequest?
        URLProtocolStub.requestObserver = { capturedRequest = $0 }

        let fetcher = LLMModelListFetcher(session: makeSession())
        let models = try await fetcher.fetchModels(provider: .claude, apiKey: "sk-ant-key")

        XCTAssertEqual(models, ["claude-sonnet-5"])
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "x-api-key"), "sk-ant-key")
        XCTAssertNotNil(capturedRequest?.value(forHTTPHeaderField: "anthropic-version"))
    }

    public func test_fetchModels_ErrorStatusThrows() async throws {
        URLProtocolStub.data = Data("{}".utf8)
        URLProtocolStub.response = try HTTPURLResponse(
            url: XCTUnwrap(URL(string: "https://api.mistral.ai/v1/models")),
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )
        let fetcher = LLMModelListFetcher(session: makeSession())
        do {
            _ = try await fetcher.fetchModels(provider: .mistral, apiKey: "bad")
            XCTFail("Expected error for 401 response")
        } catch {
            // ожидаемая ошибка
        }
    }
}
