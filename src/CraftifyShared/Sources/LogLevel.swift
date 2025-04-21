import Foundation

/// Уровень лога
public enum LogLevel: String, Codable, CaseIterable, Equatable {
    case debug = "debug"
    case error = "error"
    case info = "info"
    case warning = "warning"
}
