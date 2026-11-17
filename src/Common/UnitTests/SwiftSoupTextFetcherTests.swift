import XCTest

final class SwiftSoupTextFetcherTests: XCTestCase {
    // MARK: - Мок URLSession

    class MockURLSession: URLSessionProtocol {
        var nextData: Data?
        var nextError: Error?
        var nextResponse: URLResponse?
        func data(from url: URL) async throws -> (Data, URLResponse) {
            if let error = nextError {
                throw error
            }
            guard let data = nextData else { throw URLError(.badServerResponse) }
            return (data, nextResponse ?? HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!)
        }

        func data(for request: URLRequest) async throws -> (Data, URLResponse) {
            if request.url?.lastPathComponent == "robots.txt" {
                let data = "User-agent: *\nAllow: /".data(using: .utf8) ?? Data()
                return (data, URLResponse())
            }
            return try await data(from: request.url!)
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

    /// Страница, устроенная как статья Википедии: меню, оглавление, вкладки и подвал
    /// вокруг основного блока. Модели уходит только статья с её заголовком
    func test_fetchText_takesTheMainBlockAndDropsSiteChrome() async throws {
        let html = """
        <html><head><style>.a{}</style></head><body>
        <a href="#content">Jump to content</a>
        <header><nav aria-label="Site">Main menu Random article</nav></header>
        <nav id="toc" aria-label="Contents">Contents Effects Ethics</nav>
        <main id="content">
          <header><h1>Nocebo</h1><nav aria-label="Views">Read Edit</nav></header>
          <p>A nocebo effect is said to occur.</p>
          <script>trackVisit()</script>
        </main>
        <aside>Page tools</aside>
        <footer>Privacy policy</footer>
        </body></html>
        """
        mockSession.nextData = html.data(using: .utf8)

        let text = try await self.fetcher.fetchText(from: "https://en.wikipedia.org/wiki/Nocebo")

        XCTAssertEqual(text, "Nocebo A nocebo effect is said to occur.")
    }

    /// Без основного блока берётся вся страница, но без навигации, шапки сайта и подвала;
    /// шапка самой статьи с её заголовком остаётся
    func test_fetchText_withoutMainBlock_keepsTheArticleAndDropsNavigation() async throws {
        let html = """
        <html><body>
        <header>Site name <nav>Home Blog</nav></header>
        <div role="navigation">Breadcrumbs</div>
        <article><header><h1>Title</h1></header><p>Body text.</p></article>
        <form><label>Email</label><input type="email"><button>Subscribe</button></form>
        <footer>Copyright</footer>
        </body></html>
        """
        mockSession.nextData = html.data(using: .utf8)

        let text = try await self.fetcher.fetchText(from: "https://blog.example.com/post")

        XCTAssertEqual(text, "Title Body text.")
    }

    /// Выпадающее меню, скрытое за кнопкой (у Википедии так устроен список языков
    /// статьи), выбрасывается вместе с кнопкой даже внутри основного блока
    func test_fetchText_dropsPopupMenusInsideTheMainBlock() async throws {
        let html = """
        <html><body><main>
        <h1>Nocebo</h1>
        <div class="dropdown">
          <input type="checkbox" role="button" aria-haspopup="true" aria-label="Languages">
          <label>34 languages</label>
          <div><ul><li><a lang="de">Deutsch</a></li><li><a lang="fr">Français</a></li></ul>
          <a>Edit links</a></div>
        </div>
        <p>A nocebo effect is said to occur.</p>
        </main></body></html>
        """
        mockSession.nextData = html.data(using: .utf8)

        let text = try await self.fetcher.fetchText(from: "https://en.wikipedia.org/wiki/Nocebo")

        XCTAssertEqual(text, "Nocebo A nocebo effect is said to occur.")
    }

    /// Если на странице нет ничего, кроме служебных блоков, лучше отдать их текст,
    /// чем сообщить пользователю о пустой странице
    func test_fetchText_pageOfOnlyNavigation_fallsBackToTheWholeBody() async throws {
        let html = "<html><body><nav>Only links here</nav></body></html>"
        mockSession.nextData = html.data(using: .utf8)

        let text = try await self.fetcher.fetchText(from: "https://links.example.com")

        XCTAssertEqual(text, "Only links here")
    }

    /// Старые сайты оборачивают статью вместе с комментариями в форму (у OpenNet это
    /// форма модерации). Статья остаётся, из формы уходят только поля и кнопки
    func test_fetchText_keepsAnArticleWrappedInAForm() async throws {
        let html = """
        <html><body>
        <table><tr><td>News Forum Tags</td></tr></table>
        <form action="/cgi-bin/moderate" method="POST">
          <h1>iLeakage</h1><p>Researchers found a flaw.</p>
          <textarea>Draft comment</textarea><button>Send</button>
        </form>
        </body></html>
        """
        mockSession.nextData = html.data(using: .utf8)

        let text = try await self.fetcher.fetchText(from: "https://www.opennet.ru/opennews/art.shtml?num=60000")

        XCTAssertEqual(text, "News Forum Tags iLeakage Researchers found a flaw.")
    }

    /// Страница в кодировке из заголовка ответа сервера (OpenNet отдаёт KOI8-R)
    func test_fetchText_decodesThePageInTheCharsetTheServerDeclares() async throws {
        let koi8 = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.KOI8_R.rawValue)))
        mockSession.nextData = "<html><body><p>Привет, мир!</p></body></html>".data(using: koi8)
        let url = try XCTUnwrap(URL(string: "https://www.opennet.ru/opennews/art.shtml?num=60000"))
        mockSession.nextResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "text/html; charset=koi8-r"])

        let text = try await self.fetcher.fetchText(from: url.absoluteString)

        XCTAssertEqual(text, "Привет, мир!")
    }

    /// Страница, которая объявляет кодировку только в теге meta
    func test_fetchText_decodesThePageInTheCharsetItsMetaDeclares() async throws {
        let html = "<html><head><meta charset=\"windows-1251\"></head><body><p>Привет, мир!</p></body></html>"
        mockSession.nextData = html.data(using: .windowsCP1251)

        let text = try await self.fetcher.fetchText(from: "https://old.example.ru/page")

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
