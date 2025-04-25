@testable import Common
import Nimble
import XCTest

/// Тесты для LogManagerSharedInMemory
public final class LogManagerSharedInMemoryTests: XCTestCase {
    private let module = "TestModule"
    private let message = "Test message"
    private let metadata = ["foo": "bar"]

    /// Проверяет запись и чтение логов (FIFO)
    public func testLogAndGetLogs() {
        let logger = LogManagerSharedInMemory(maxLogCount: 10)
        let entry1 = LogEntry(level: .info, module: module, message: message, metadata: metadata)
        let entry2 = LogEntry(level: .error, module: module, message: "Error", metadata: [:])
        logger.log(entry1)
        logger.log(entry2)
        let logs = logger.getLogs()
        expect(logs.count).to(equal(2))
        expect(logs[0]).to(equal(entry1))
        expect(logs[1]).to(equal(entry2))
    }

    /// Проверяет удаление логов
    public func testClearLogs() {
        let logger = LogManagerSharedInMemory(maxLogCount: 10)
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
        expect(logs.count).to(equal(2))
        expect(logs[0]).to(equal(entry2))
        expect(logs[1]).to(equal(entry3))
    }

    /// Проверяет экспорт логов в JSON
    public func testExportLogs() throws {
        let logger = LogManagerSharedInMemory(maxLogCount: 10)
        let entry = LogEntry(level: .debug, module: module, message: message, metadata: metadata)
        logger.log(entry)
        let data = try logger.exportLogs()
        let decoded = try JSONDecoder().decode([LogEntry].self, from: data)
        expect(decoded).to(equal([entry]))
    }

    /// Проверяет уровни логов
    public func testLogLevels() {
        let logger = LogManagerSharedInMemory(maxLogCount: 10)
        let entry = LogEntry(level: .warning, module: module, message: message, metadata: metadata)
        logger.log(entry)
        let logs = logger.getLogs()
        expect(logs.first?.level).to(equal(.warning))
    }

    /// Очистка ресурсов (stub)
    deinit { /* nothing to cleanup */ }
}
