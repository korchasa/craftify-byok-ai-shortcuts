import Foundation

/// In-memory реализация LogManagerShared для тестов
public final class LogManagerSharedInMemory: LogManagerShared {
    public static let defaultMaxLogCount = 1_000
    private static let minKeyLength = 8
    private static let maskLength = 4
    private var logs: [LogEntry] = []
    public let maxLogCount: Int

    /// Инициализация in-memory логгера
    /// - Parameter maxLogCount: Максимальное количество логов (FIFO)
    public init(maxLogCount: Int = LogManagerSharedInMemory.defaultMaxLogCount) {
        self.maxLogCount = max(LogManagerSharedInMemory.defaultMaxLogCount, maxLogCount)
    }

    /// Записать лог
    public func log(_ entry: LogEntry) {
        logs.append(entry)
        if logs.count > maxLogCount {
            logs.removeFirst(logs.count - maxLogCount)
        }
    }

    /// Прочитать все логи (FIFO)
    public func getLogs() -> [LogEntry] {
        logs
    }

    /// Удалить все логи
    public func clearLogs() {
        logs.removeAll()
    }

    /// Экспортировать логи в Data (JSON)
    public func exportLogs() throws -> Data {
        let maskedLogs = logs.map { entry -> LogEntry in
            var maskedMetadata = entry.metadata
            if let apiKey = maskedMetadata["apiKey"] {
                maskedMetadata["apiKey"] = maskKey(apiKey)
            }
            return LogEntry(
                level: entry.level,
                module: entry.module,
                message: entry.message,
                metadata: maskedMetadata,
                timestamp: entry.timestamp
            )
        }
        return try JSONEncoder().encode(maskedLogs)
    }

    /// Очистка ресурсов (stub)
    deinit { /* nothing to cleanup */ }
}
