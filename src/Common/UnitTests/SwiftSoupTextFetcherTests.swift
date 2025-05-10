import XCTest

final class SwiftSoupTextFetcherTests: XCTestCase {
    // MARK: - Мок URLSession

    class MockURLSession: URLSessionProtocol {
        var nextData: Data?
        var nextError: Error?
        var nextResponse: URLResponse?
        func data(from url: URL) async throws -> (Data, URLResponse) {
            if let error = nextError { throw error }
            guard let data = nextData else { throw URLError(.badServerResponse) }
            return (data, nextResponse ?? URLResponse())
        }
    }

    var fetcher: SwiftSoupTextFetcher!
    var mockSession: MockURLSession!

    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
        fetcher = SwiftSoupTextFetcher(session: mockSession)
    }

    func test_fetchText_badURL_throws() async {
        do {
            _ = try await self.fetcher.fetchText(from: "not a url")
            XCTFail("Expected FetchError.badURL, but got success")
        } catch {
            if let fetchError = error as? FetchError {
                XCTAssertEqual(fetchError, .badURL)
            } else {
                XCTFail("Unexpected error: \(error.localizedDescription)")
            }
        }
    }

    func test_fetchText_networkError_throws() async {
        mockSession.nextError = URLError(.notConnectedToInternet)
        do {
            _ = try await self.fetcher.fetchText(from: "https://unreachable.example.com")
            XCTFail("Expected FetchError.downloadFailed, but got success")
        } catch {
            if let fetchError = error as? FetchError {
                XCTAssertEqual(fetchError, .downloadFailed)
            } else {
                XCTFail("Unexpected error: \(error.localizedDescription)")
            }
        }
    }

    func test_fetchText_decodeError_throws() async {
        mockSession.nextData = Data([0xFF, 0xFF, 0xFF]) // Некорректная строка
        do {
            _ = try await self.fetcher.fetchText(from: "https://invalid-encoding.example.com")
            XCTFail("Expected FetchError.noData, but got success")
        } catch {
            if let fetchError = error as? FetchError {
                XCTAssertEqual(fetchError, .noData)
            } else {
                XCTFail("Unexpected error: \(error.localizedDescription)")
            }
        }
    }

    func test_fetchText_success_extractsText() async throws {
        let html = "<html><body>Привет, мир!</body></html>"
        mockSession.nextData = html.data(using: .utf8)
        let text = try await self.fetcher.fetchText(from: "https://test.com")
        XCTAssertEqual(text, "Привет, мир!")
    }
}

// MARK: - Async Error Assertion Helper

extension XCTestCase {
    func XCTAssertThrowsErrorAsync(_ expression: @autoclosure @escaping () async throws -> some Any, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line, _ errorHandler: (Error) -> Void = { _ in }) async {
        do {
            _ = try await expression()
            XCTFail("Expected error but got success", file: file, line: line)
        } catch {
            errorHandler(error)
        }
    }
}
