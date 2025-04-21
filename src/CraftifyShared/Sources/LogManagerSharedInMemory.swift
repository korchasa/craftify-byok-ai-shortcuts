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
        self.maxLogCount = maxLogCount
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
        return logs
    }

    /// Удалить все логи
    public func clearLogs() {
        logs.removeAll()
    }

    /// Экспортировать логи в Data (JSON)
    public func exportLogs() throws -> Data {
        return try JSONEncoder().encode(logs)
    }

    /// Маскировать API-ключ в строке
    public func maskAPIKey(_ key: String?) -> String {
        guard let key, key.count > Self.minKeyLength else {
            return "********"
        }
        let prefix = key.prefix(Self.maskLength)
        let suffix = key.suffix(Self.maskLength)
        return "\(prefix)****\(suffix)"
    }

    /// Очистка ресурсов (stub)
    deinit { /* nothing to cleanup */ }
}
