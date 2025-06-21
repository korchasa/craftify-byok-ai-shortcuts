import Foundation

/// Thread-safe in-memory cache for `robots.txt` rules (expires after 1 hour).
public actor RobotsCache {
    // MARK: - Constants

    private static let expirySeconds: TimeInterval = 3600 // 1 hour

    // MARK: - Shared

    /// Singleton instance used across the app.
    public static let shared = RobotsCache()

    // MARK: - State

    private var storage: [String: (text: String, date: Date)] = [:]

    // MARK: - API

    /// Returns cached content if it exists and hasn't expired.
    /// - Parameter host: Hostname (e.g. "example.com").
    /// - Returns: `robots.txt` content or `nil`.
    public func get(for host: String) -> String? {
        guard let entry = storage[host] else { return nil }
        if Date().timeIntervalSince(entry.date) > RobotsCache.expirySeconds {
            storage.removeValue(forKey: host)
            return nil
        }
        return entry.text
    }

    /// Stores the provided `robots.txt` for the host.
    /// - Parameters:
    ///   - robotsTxt: Raw file content.
    ///   - host: Hostname.
    public func set(_ robotsTxt: String, for host: String) {
        storage[host] = (robotsTxt, Date())
    }

    /// Clears the entire cache (unit-test helper).
    public func clear() {
        storage.removeAll()
    }

    deinit {}
}
