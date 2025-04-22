@testable import CraftifyShared
import Nimble
import XCTest

/// Тесты для LogManagerSharedInMemory
public final class LogManagerSharedInMemoryTests: XCTestCase {
    private let module = "TestModule"
    private let message = "Test message"
    private let metadata = ["foo": "bar"]
    private let apiKey = "sk-12345678ABCDEFGH"

    /// Проверяет запись и чтение логов (FIFO)
    public func testLogAndGetLogs() {
        let logger = LogManagerSharedInMemory(maxLogCount: 3)
        let entry1 = LogEntry(level: .info, module: module, message: message, metadata: metadata)
        let entry2 = LogEntry(level: .error, module: module, message: "Error", metadata: [:])
        logger.log(entry1)
        logger.log(entry2)
        let logs = logger.getLogs()
        expect(logs.count) == 2
        expect(logs[0]) == entry1
        expect(logs[1]) == entry2
    }

    /// Проверяет удаление логов
    public func testClearLogs() {
        let logger = LogManagerSharedInMemory()
        logger.log(LogEntry(level: .info, module: module, message: message, metadata: metadata))
        logger.clearLogs()
        expect(logger.getLogs()).to(beEmpty())
    }

    /// Проверяет FIFO-очистку при превышении лимита
    public func testFIFOEviction() {
        let logger = LogManagerSharedInMemory(maxLogCount: 2)
        let entry1 = LogEntry(level: .info, module: module, message: "1", metadata: [:])
        let entry2 = LogEntry(level: .info, module: module, message: "2", metadata: [:])
        let entry3 = LogEntry(level: .info, module: module, message: "3", metadata: [:])
        logger.log(entry1)
        logger.log(entry2)
        logger.log(entry3)
        let logs = logger.getLogs()
        expect(logs.count) == 2
        expect(logs[0]) == entry2
        expect(logs[1]) == entry3
    }

    /// Проверяет экспорт логов в JSON
    public func testExportLogs() throws {
        let logger = LogManagerSharedInMemory()
        let entry = LogEntry(level: .debug, module: module, message: message, metadata: metadata)
        logger.log(entry)
        let data = try logger.exportLogs()
        let decoded = try JSONDecoder().decode([LogEntry].self, from: data)
        expect(decoded) == [entry]
    }

    /// Проверяет маскирование API-ключа
    public func testMaskAPIKey() {
        let logger = LogManagerSharedInMemory()
        let masked = logger.maskAPIKey(apiKey)
        expect(masked).to(beginWith("sk-1"))
        expect(masked).to(endWith("EFGH"))
        expect(masked).to(contain("****"))
        expect(masked.count) == 12
    }

    /// Проверяет маскирование короткого ключа
    public func testMaskShortAPIKey() {
        let logger = LogManagerSharedInMemory()
        let masked = logger.maskAPIKey("short")
        expect(masked) == "********"
    }

    /// Проверяет уровни логов
    public func testLogLevels() {
        let logger = LogManagerSharedInMemory()
        let entry = LogEntry(level: .warning, module: module, message: message, metadata: metadata)
        logger.log(entry)
        let logs = logger.getLogs()
        expect(logs.first?.level) == .warning
    }

    /// Очистка ресурсов (stub)
    deinit { /* nothing to cleanup */ }
}
