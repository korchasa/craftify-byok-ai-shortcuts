import Foundation

/// Реализация LogManagerShared на NDJSON-файле (App Group)
public final class LogManagerSharedNDJSON: LogManagerShared {
    private static let logsFileName = "logs.ndjson"
    public static let maxLogCountDefault = 1_000
    private static let minKeyLengthToMask = 8
    private static let maskLength = 4

    private let fileURL: URL
    private let maxLogCount: Int
    private let queue = DispatchQueue(label: "LogManagerSharedNDJSONQueue")

    /// Инициализация менеджера логов с указанием контейнера и лимита
    public init(appGroupContainerURL: URL, maxLogCount: Int = maxLogCountDefault) {
        self.fileURL = appGroupContainerURL.appendingPathComponent(Self.logsFileName)
        self.maxLogCount = maxLogCount
    }

    /// Записать лог в NDJSON-файл
    public func log(_ entry: LogEntry) {
        queue.sync {
            var logs = readAllLogs()
            logs.append(entry)
            if logs.count > maxLogCount {
                logs.removeFirst(logs.count - maxLogCount)
            }
            writeAllLogs(logs)
        }
    }

    /// Прочитать все логи (FIFO)
    public func getLogs() -> [LogEntry] {
        queue.sync {
            readAllLogs()
        }
    }

    /// Удалить все логи
    public func clearLogs() {
        queue.sync {
            try? Data().write(to: fileURL, options: .atomic)
        }
    }

    /// Экспортировать логи в Data (JSON)
    public func exportLogs() throws -> Data {
        let logs = getLogs()
        return try JSONEncoder().encode(logs)
    }

    /// Маскировать API-ключ в строке
    public func maskAPIKey(_ key: String?) -> String {
        guard let key, key.count > Self.minKeyLengthToMask else {
            return "********"
        }
        let prefix = key.prefix(Self.maskLength)
        let suffix = key.suffix(Self.maskLength)
        return "\(prefix)****\(suffix)"
    }

    // MARK: - Private helpers

    private func readAllLogs() -> [LogEntry] {
        let data: Data
        if let dataValue = try? Data(contentsOf: fileURL), !dataValue.isEmpty {
            data = dataValue
        } else {
            return []
        }
        let content: String
        if let contentString = String(data: data, encoding: .utf8) {
            content = contentString
        } else {
            return []
        }
        return content
            .split(separator: "\n")
            .compactMap { try? JSONDecoder().decode(LogEntry.self, from: Data($0.utf8)) }
    }

    private func writeAllLogs(_ logs: [LogEntry]) {
        let lines = logs.compactMap { entry -> String? in
            guard let data = try? JSONEncoder().encode(entry), let str = String(data: data, encoding: .utf8) else { return nil }
            return str
        }
        let ndjson = lines.joined(separator: "\n")
        try? ndjson.data(using: .utf8)?.write(to: fileURL, options: .atomic)
    }

    deinit { /* nothing to cleanup */ }
}
