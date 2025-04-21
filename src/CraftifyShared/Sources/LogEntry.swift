import Foundation

/// Структура записи лога
public struct LogEntry: Codable, Equatable {
    public let level: LogLevel
    public let module: String
    public let message: String
    public let metadata: [String: String]
    public let timestamp: Date

    /// Создаёт запись лога
    public init(
        level: LogLevel,
        module: String,
        message: String,
        metadata: [String: String] = [:],
        timestamp: Date = Date()
    ) {
        self.level = level
        self.module = module
        self.message = message
        self.metadata = metadata
        self.timestamp = timestamp
    }
}
