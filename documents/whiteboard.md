# ADR: Интеграция YouTubeSubtitleFetcher в SummarizeOperation

**Дата:** 2024-06-XX
**Статус:** Предложено

## Контекст и проблема
- В модуле `Common` используется протокол `TextFetching`, и по умолчанию для любых URL в `SummarizeOperation` применяется `SwiftSoupTextFetcher`, который извлекает видимый HTML-текст.
- При расшаре ссылок YouTube необходимо загружать не HTML-страницу, а субтитры видео (WebVTT → plain text) и передавать их на вход LLM вместе с метаданными (заголовок, автор, длительность).
- `fetchText(from:)` протокол требует возвращать `String`; для YouTube это будет объединённый текст: "<Заголовок>\n\n<Субтитры>".

## Цели и ограничения
- Сохранить совместимость с существующим протоколом `TextFetching` и DI-конфигурацией в `SummarizeOperation`.
- Для YouTube URL (домен `youtube.com` или `youtu.be`) внедрить специальную логику загрузки субтитров через парсинг `ytInitialPlayerResponse` без API-ключей.
- Для всех остальных URL оставить `SwiftSoupTextFetcher`.
- Использовать Swift 5.5+, async/await, iOS 16+.
- Не локализовать бизнес-логику в Common (ошибки — чистые `Error`).

## Варианты решения
1. Использовать YouTube Data API (API-ключи, квоты) — **не подходит**.
2. Интегрировать yt-dlp (Python) — **не подходит** для iOS.
3. Парсить публичный HTML/JS (`ytInitialPlayerResponse`) — **выбранный вариант**.

## Решение
1. Создать `YouTubeSubtitleFetcher: TextFetching` в `src/Common/Sources/TextFetcher/YouTubeSubtitleFetcher.swift`.
2. В `SummarizeOperation` (в `init(textFetcher:)` или в фабрике) определить:
   ```swift
   let fetcher: TextFetching
   if url.host?.contains("youtube.com") == true || url.host?.contains("youtu.be") == true {
       fetcher = YouTubeSubtitleFetcher(session: session, logManager: log)
   } else {
       fetcher = SwiftSoupTextFetcher(session: session, logManager: log)
   }
   ```
3. Интерфейс `YouTubeSubtitleFetcher`:
   ```swift
   public final class YouTubeSubtitleFetcher: TextFetching {
       public init(
           session: URLSession = .shared,
           logManager: LogManagerShared = .shared
       ) { ... }

       public func fetchText(from urlString: String) async throws -> String { ... }

       public func fetchAndExtractText(
           from urlString: String,
           completion: @escaping (Result<String, Error>) -> Void
       ) { ... }
   }
   ```
4. Логика в `fetchText(from:)`:
   - **Парсинг ID:** извлечь `videoID` из `urlString`.
   - **fetchVideoHTML(videoID:)**: загрузить HTML страницы.
   - **extractPlayerJSON(html:)**: найти и десериализовать `ytInitialPlayerResponse`.
   - **parseCaptionTracks(data:)**: получить `[CaptionTrack]` и выбрать (приоритет `ru`, иначе первый).
   - **downloadVTT(baseUrl:)**: загрузить WebVTT.
   - **convertVTTtoPlainText(vtt:)**: перевести WebVTT в простую строку.
   - **Формирование результата:** `"\(title)\n\n\(subtitlesPlain)"`.

## Пример кода (основные части)
```swift
// MARK: — Модели
struct PlayerResponse: Decodable { let captions: CaptionsContainer? }
struct CaptionsContainer: Decodable { let playerCaptionsTracklistRenderer: TracklistRenderer }
struct TracklistRenderer: Decodable { let captionTracks: [CaptionTrack] }
struct CaptionTrack: Decodable { let baseUrl: String; let name: Name; let languageCode: String }
struct Name: Decodable { let simpleText: String }

enum YouTubeError: Error {
    case invalidURL, noHTML, jsonNotFound, decodingFailed, noCaptions, downloadFailed
}

public final class YouTubeSubtitleFetcher: TextFetching {
    private let session: URLSession
    private let log: LogManagerShared

    public init(session: URLSession = .shared,
                logManager: LogManagerShared = .shared) {
        self.session = session
        self.log = logManager
    }

    public func fetchText(from urlString: String) async throws -> String {
        // 1. Parse videoID
        guard let videoID = URLComponents(string: urlString)?
                .queryItems?.first(where: { $0.name == "v" })?.value
        else { throw YouTubeError.invalidURL }

        // 2. HTML
        let html = try await fetchVideoHTML(videoID: videoID)
        // 3. JSON
        let jsonData = try extractPlayerJSON(from: html)
        // 4. Tracks
        let tracks = try parseCaptionTracks(from: jsonData)
        let track = tracks.first(where: { $0.languageCode == "ru" }) ?? tracks.first
        guard let baseUrl = track?.baseUrl else { throw YouTubeError.noCaptions }
        // 5. VTT
        let vtt = try await downloadVTT(from: baseUrl)
        // 6. Plain text
        let subtitles = convertVTTtoPlainText(vtt)
        // 7. Title (опционально извлечь из JSON аналогично)
        let title = try parseVideoTitle(from: jsonData)
        return "\(title)\n\n\(subtitles)"
    }

    public func fetchAndExtractText(
        from urlString: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        Task {
            do {
                let text = try await fetchText(from: urlString)
                completion(.success(text))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
```

## Последствия и риски
- + Автономная работа без ключей.
- + Интегрируется в существующий DI и SummarizeOperation.
- – Уязвимо к изменениям структуры YouTube.

## План реализации (TDD)
1. **Red**: тест для `extractPlayerJSON` на сохранённом HTML.
2. **Green**: реализация `extractPlayerJSON`.
3. Тесты для `parseCaptionTracks`, `downloadVTT`, `convertVTTtoPlainText`.
4. **Red**: интеграционный тест `fetchText` с моком URLSession.
5. **Green**: реализация `fetchText` и `fetchAndExtractText`.
6. **Refactor**: кодстайл, убрать дубли, обновить `code-style-swift.md` при необходимости.
7. Запустить `./run check` и исправить все ошибки, предупреждения, форматирование и ленты.

