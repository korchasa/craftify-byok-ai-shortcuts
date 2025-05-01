import Foundation
import os

/// Implementation of LogManagerShared that writes logs to the unified iOS log using OSLog
public final class OSLogManagerShared: LogManagerShared {
    private let logger: OSLog

    /// Initialize with an optional subsystem and category for grouping logs
    /// - Parameters:
    ///   - subsystem: The subsystem identifier, defaults to the app bundle identifier
    ///   - category: The log category, defaults to "Default"
    public init(category: String = "Default") {
        logger = OSLog(subsystem: "Internal", category: category)
    }

    /// Write a log entry to the unified log
    public func log(_ entry: LogEntry) {
        let message = "\(entry.message) \(entry.metadata)"
        os_log("%{public}@", log: logger, type: .info, message)
    }

    /// No-op: unified log does not support reading back previous entries
    public func getLogs() -> [LogEntry] {
        []
    }

    /// No-op clear
    public func clearLogs() {
        // No file to clear when using unified log
    }

    /// No-op export
    public func exportLogs() throws -> Data {
        Data()
    }

    deinit {}
}
