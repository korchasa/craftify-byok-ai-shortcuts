import XCTest

final class SwiftSoupTextFetcherRobotsTests: XCTestCase {
    // MARK: - Мок URLSession

    final class MockURLSession: URLSessionProtocol {
        var responses: [String: (Data, URLResponse)] = [:] // key = path
        func data(from url: URL) async throws -> (Data, URLResponse) {
            if let tuple = responses[url.path] {
                return tuple
            }
            throw URLError(.unsupportedURL)
        }

        func data(for request: URLRequest) async throws -> (Data, URLResponse) {
            guard let url = request.url else { throw URLError(.badURL) }
            return try await data(from: url)
        }
    }

    var fetcher: SwiftSoupTextFetcher!
    var mockSession: MockURLSession!

    override func setUp() {
        super.setUp()
        Task { await RobotsCache.shared.clear() }
        mockSession = MockURLSession()
        fetcher = SwiftSoupTextFetcher(session: mockSession)
    }

    /// Проверяем, что Disallow запрещает доступ
    func test_fetchText_disallowedByRobots_throws() async throws {
        let robotsTxt = "User-agent: *\nDisallow: /protected"
        mockSession.responses["/protected/robots.txt"] = try (XCTUnwrap(robotsTxt.data(using: .utf8)), XCTUnwrap(try HTTPURLResponse(url: XCTUnwrap(URL(string: "https://example.com/protected/robots.txt")), statusCode: 200, httpVersion: nil, headerFields: nil)))
        mockSession.responses["/protected/page.html"] = try (XCTUnwrap("<html><body>secret</body></html>".data(using: .utf8)), XCTUnwrap(try HTTPURLResponse(url: XCTUnwrap(URL(string: "https://example.com/protected/page.html")), statusCode: 200, httpVersion: nil, headerFields: nil)))
        do {
            _ = try await fetcher.fetchText(from: "https://example.com/protected/page.html")
            XCTFail("Expected disallowed error")
        } catch {
            XCTAssertEqual(error as? FetchError, .disallowedByRobots)
        }
    }

    /// Проверяем, что meta noindex запрещает доступ
    func test_fetchText_metaNoindex_throws() async throws {
        let robotsTxt = "User-agent: *\nAllow: /"
        mockSession.responses["/robots.txt"] = try (XCTUnwrap(robotsTxt.data(using: .utf8)), XCTUnwrap(try HTTPURLResponse(url: XCTUnwrap(URL(string: "https://example.com/robots.txt")), statusCode: 200, httpVersion: nil, headerFields: nil)))
        let html = "<html><head><meta name=\"robots\" content=\"noindex\"></head><body>Hello</body></html>"
        mockSession.responses["/page.html"] = try (XCTUnwrap(html.data(using: .utf8)), XCTUnwrap(try HTTPURLResponse(url: XCTUnwrap(URL(string: "https://example.com/page.html")), statusCode: 200, httpVersion: nil, headerFields: nil)))
        do {
            _ = try await fetcher.fetchText(from: "https://example.com/page.html")
            XCTFail("Expected disallowed error")
        } catch {
            XCTAssertEqual(error as? FetchError, .disallowedByRobots)
        }
    }

    /// Проверяем успешный кейс
    func test_fetchText_allowed_success() async throws {
        let robotsTxt = "User-agent: *\nAllow: /"
        mockSession.responses["/robots.txt"] = try (XCTUnwrap(robotsTxt.data(using: .utf8)), XCTUnwrap(try HTTPURLResponse(url: XCTUnwrap(URL(string: "https://example.com/robots.txt")), statusCode: 200, httpVersion: nil, headerFields: nil)))
        let html = "<html><body>Allowed</body></html>"
        mockSession.responses["/allowed.html"] = try (XCTUnwrap(html.data(using: .utf8)), XCTUnwrap(try HTTPURLResponse(url: XCTUnwrap(URL(string: "https://example.com/allowed.html")), statusCode: 200, httpVersion: nil, headerFields: nil)))
        let text = try await fetcher.fetchText(from: "https://example.com/allowed.html")
        XCTAssertEqual(text, "Allowed")
    }
}
