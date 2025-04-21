import Foundation

/// Протокол для менеджера логов, поддерживающего FIFO, экспорт и маскирование ключей
public protocol LogManagerShared: AnyObject {
    /// Записать лог
    func log(_ entry: LogEntry)
    /// Прочитать все логи (FIFO)
    func getLogs() -> [LogEntry]
    /// Удалить все логи
    func clearLogs()
    /// Экспортировать логи в Data (JSON)
    func exportLogs() throws -> Data
    /// Маскировать API-ключ в строке
    func maskAPIKey(_ key: String?) -> String
}
