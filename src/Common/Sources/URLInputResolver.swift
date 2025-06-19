import Foundation

/// Centralised helper that converts a URL into plain text using a pluggable `TextFetching` implementation.
///
/// The public API is intentionally minimal:
/// 1. `resolve(urlString:logManager:)` – async/await single-shot fetch.
/// 2. `setTextFetcher(_:)` – allows unit-tests to inject a stub so we can avoid network traffic.
///
/// Production code never calls `setTextFetcher`; it relies on the default `SwiftSoupTextFetcher`.
/// Tests can override the fetcher before invoking the code under test.
public enum URLInputResolver {
    // MARK: - Private

    /// Shared fetcher instance used by all operations. In production this is `SwiftSoupTextFetcher`.
    private static var _fetcher: TextFetching = SwiftSoupTextFetcher()

    // MARK: - Configuration

    /// Replaces the shared `TextFetching` instance.
    /// - Parameter fetcher: Custom implementation (e.g. stub) used from now on.
    public static func setTextFetcher(_ fetcher: TextFetching) {
        _fetcher = fetcher
    }

    // MARK: - Public API

    /// Resolves the provided URL into readable plain text.
    /// - Parameters:
    ///   - urlString: HTTP/HTTPS URL string.
    ///   - logManager: Optional logger (used by custom fetchers for debugging).
    /// - Returns: Extracted text.
    /// - Throws: `UserFacingError` produced by the underlying `TextFetching` implementation.
    public static func resolve(urlString: String, logManager _: LogManagerShared?) async throws -> String {
        try await _fetcher.fetchText(from: urlString)
    }
}
