import Foundation
import SwiftSoup

/// Реализация TextFetching с использованием SwiftSoup
public final class SwiftSoupTextFetcher: TextFetching {
    private let session: URLSessionProtocol
    private let logManager: LogManagerShared?
    public init(session: URLSessionProtocol = URLSession.shared, logManager: LogManagerShared? = nil) {
        self.session = session
        self.logManager = logManager
    }

    deinit {}

    public func fetchText(from urlString: String) async throws -> String {
        let start = Date()
        logManager?.log(LogEntry(
            level: .debug,
            module: "TextFetcher",
            message: "Start fetchText",
            metadata: ["url": urlString],
            timestamp: start
        ))
        guard let url = URL(string: urlString) else { throw FetchError.badURL }
        let (data, _) = try await session.data(from: url)
        let afterNetwork = Date()
        let htmlSize = data.count
        logManager?.log(LogEntry(
            level: .debug,
            module: "TextFetcher",
            message: "Fetched HTML",
            metadata: [
                "url": urlString,
                "duration": String(format: "%.3f", afterNetwork.timeIntervalSince(start)),
                "size": "\(htmlSize)"
            ],
            timestamp: afterNetwork
        ))
        guard let html = String(data: data, encoding: .utf8) else { throw FetchError.noData }
        let parseStart = Date()
        do {
            let document = try SwiftSoup.parse(html)
            guard let body = document.body() else { throw FetchError.parseError }
            let text = try body.text()
            let afterParse = Date()
            logManager?.log(LogEntry(
                level: .debug,
                module: "TextFetcher",
                message: "Parsed text",
                metadata: [
                    "url": urlString,
                    "duration": String(format: "%.3f", afterParse.timeIntervalSince(parseStart)),
                    "size": "\(text.count)"
                ],
                timestamp: afterParse
            ))
            return text
        } catch {
            throw FetchError.parseError
        }
    }

    public func fetchAndExtractText(from urlString: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(FetchError.badURL))
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let data, let html = String(data: data, encoding: .utf8) else {
                completion(.failure(FetchError.noData))
                return
            }
            do {
                let document = try SwiftSoup.parse(html)
                guard let body = document.body() else { completion(.failure(FetchError.parseError))
                    return
                }
                try completion(.success(body.text()))
            } catch {
                completion(.failure(FetchError.parseError))
            }
        }.resume()
    }
}
