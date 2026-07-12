import Foundation
import SwiftSoup

/// Реализация TextFetching с использованием SwiftSoup
public final class SwiftSoupTextFetcher: TextFetching {
    private enum Constants {
        static let metaTagScanLimit = 250
    }

    private let session: URLSessionProtocol
    private let logManager: LogManagerShared?
    public init(session: URLSessionProtocol = URLSession.shared, logManager: LogManagerShared? = nil) {
        self.session = session
        self.logManager = logManager
    }

    deinit {}

    /// Загружает и извлекает текст из HTML по URL. Бросает подробные ошибки для пользователя.
    public func fetchText(from urlString: String) async throws -> String {
        let userAgent = "CraftifyBot/1.0 (+https://craftify.app/robots)"
        let start = Date()
        logManager?.log(LogEntry(
            level: .debug,
            module: "TextFetcher",
            message: "Start fetchText",
            metadata: ["url": urlString],
            timestamp: start
        ))
        guard let url = URL(string: urlString), let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            throw FetchError.badURL
        }

        // Проверяем robots.txt
        if await !isAllowedByRobots(url: url, userAgent: userAgent) {
            throw FetchError.disallowedByRobots
        }

        // Загружаем HTML с кастомным User-Agent
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw FetchError.downloadFailed
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FetchError.downloadFailed
        }
        // Проверка X-Robots-Tag
        if let robotsHeader = httpResponse.value(forHTTPHeaderField: "X-Robots-Tag")?.lowercased(), robotsHeader.contains("noindex") || robotsHeader.contains("none") {
            throw FetchError.disallowedByRobots
        }

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
        // Проверка meta robots
        if html.lowercased().contains("<meta name=\"robots\""), let idx = html.range(of: "<meta name=\"robots\"", options: .caseInsensitive)?.lowerBound {
            // Extract tag substring up to '>' maybe 250 chars ahead
            let substring = html[idx...].prefix(Constants.metaTagScanLimit).lowercased()
            if substring.contains("noindex") || substring.contains("none") {
                throw FetchError.disallowedByRobots
            }
        }

        let parseStart = Date()
        do {
            let document = try SwiftSoup.parse(html)
            guard let body = document.body() else { throw FetchError.parseError }
            let text = try body.text()
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw FetchError.emptyText
            }
            let afterParse = Date()
            logManager?.log(LogEntry(
                level: .debug,
                module: "TextFetcher",
                message: "Parsed text",
                metadata: [
                    "url": urlString,
                    "duration": String(format: "%.3f", afterParse.timeIntervalSince(parseStart)),
                    "size": "\(text.count)",
                    "text": text
                ],
                timestamp: afterParse
            ))
            return text
        } catch {
            let userError = FetchError.parseError.userFacingError
            let detailedError = UserFacingError(
                messageKey: userError.messageKey,
                adviceKey: userError.adviceKey,
                titleKey: userError.titleKey,
                underlyingError: error
            )
            logManager?.log(LogEntry(
                level: .error,
                module: "TextFetcher",
                message: "SwiftSoup parsing failed: \(error.localizedDescription)",
                metadata: [
                    "url": urlString,
                    "swiftSoupError": String(describing: error)
                ],
                timestamp: Date()
            ))
            throw detailedError
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

    // MARK: - Robots

    /// Проверяет robots.txt и кэширует результат. Возвращает `true`, если доступ разрешён.
    private func isAllowedByRobots(url: URL, userAgent: String) async -> Bool {
        guard let host = url.host else { return true }
        let cache = RobotsCache.shared
        if let robotsTxt = await cache.get(for: host) {
            return RobotsTxtParser.isAllowed(userAgent: userAgent, url: url, robotsTxt: robotsTxt)
        }
        // Скачиваем robots.txt
        var robotsURL = url
        robotsURL.deleteLastPathComponent()
        robotsURL.appendPathComponent("robots.txt")
        var robotsRequest = URLRequest(url: robotsURL)
        robotsRequest.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        do {
            let (data, _) = try await session.data(for: robotsRequest)
            if let robotsTxt = String(data: data, encoding: .utf8) {
                await cache.set(robotsTxt, for: host)
                return RobotsTxtParser.isAllowed(userAgent: userAgent, url: url, robotsTxt: robotsTxt)
            }
            // Если не удаётся декодировать, считаем разрешённым.
            return true
        } catch {
            // Если robots.txt недоступен – по умолчанию разрешаем.
            return true
        }
    }
}
