@testable import CraftifyShared
import Nimble
import XCTest

/// Тесты для LogManagerSharedNDJSON
public final class LogManagerSharedNDJSONTests: XCTestCase {
    private var tempDir: URL?
    private let module = "TestModule"
    private let message = "Test message"
    private let metadata = ["foo": "bar"]

    override public func setUp() {
        super.setUp()
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        tempDir = dir
        // Удаляем файл логов, если он есть
        let logPath = dir.appendingPathComponent("logs.ndjson").path
        try? FileManager.default.removeItem(atPath: logPath)
    }

    override public func tearDown() {
        if let tempDir {
            try? FileManager.default.removeItem(at: tempDir)
        }
        tempDir = nil
        super.tearDown()
    }

    /// Проверяет создание и запись/чтение логов (FIFO)
    public func testLogAndGetLogs() {
        if let tempDir {
            let logger = LogManagerSharedNDJSON(appGroupContainerURL: tempDir, maxLogCount: 10)
            logger.clearLogs()
            let logPath = tempDir.appendingPathComponent("logs.ndjson").path
            let fixedDate = Date(timeIntervalSince1970: 1_234_567_890)
            let entry1 = LogEntry(level: .info, module: module, message: message, metadata: metadata, timestamp: fixedDate)
            let entry2 = LogEntry(level: .error, module: module, message: "Error", metadata: [:], timestamp: fixedDate)
            logger.log(entry1)
            logger.log(entry2)
            let logs = logger.getLogs()
            expect(logs.count).to(equal(2))
            expect(logs[0]).to(equal(entry1))
            expect(logs[1]).to(equal(entry2))
        } else {
            XCTFail("tempDir is nil")
        }
    }

    /// Проверяет удаление логов
    public func testClearLogs() {
        if let tempDir {
            let logger = LogManagerSharedNDJSON(appGroupContainerURL: tempDir, maxLogCount: 10)
            logger.clearLogs()
            let fixedDate = Date(timeIntervalSince1970: 1_234_567_890)
            logger.log(LogEntry(level: .info, module: module, message: message, metadata: metadata, timestamp: fixedDate))
            logger.clearLogs()
            let logs = logger.getLogs()
            expect(logs).to(beEmpty())
        } else {
            XCTFail("tempDir is nil")
        }
    }

    /// Проверяет FIFO-очистку при превышении лимита
    public func testFIFOEviction() {
        if let tempDir {
            let logger = LogManagerSharedNDJSON(appGroupContainerURL: tempDir, maxLogCount: 2)
            logger.clearLogs()
            let fixedDate = Date(timeIntervalSince1970: 1_234_567_890)
            let entry1 = LogEntry(level: .info, module: module, message: "1", metadata: [:], timestamp: fixedDate)
            let entry2 = LogEntry(level: .info, module: module, message: "2", metadata: [:], timestamp: fixedDate)
            let entry3 = LogEntry(level: .info, module: module, message: "3", metadata: [:], timestamp: fixedDate)
            logger.log(entry1)
            logger.log(entry2)
            logger.log(entry3)
            let logs = logger.getLogs()
            expect(logs.count).to(equal(2))
            expect(logs[0]).to(equal(entry2))
            expect(logs[1]).to(equal(entry3))
        } else {
            XCTFail("tempDir is nil")
        }
    }

    /// Проверяет экспорт логов в JSON
    public func testExportLogs() throws {
        if let tempDir {
            let logger = LogManagerSharedNDJSON(appGroupContainerURL: tempDir, maxLogCount: 10)
            logger.clearLogs()
            let fixedDate = Date(timeIntervalSince1970: 1_234_567_890)
            let entry = LogEntry(level: .debug, module: module, message: message, metadata: metadata, timestamp: fixedDate)
            logger.log(entry)
            let data = try logger.exportLogs()
            let decoded = try JSONDecoder().decode([LogEntry].self, from: data)
            expect(decoded).to(equal([entry]))
        } else {
            XCTFail("tempDir is nil")
        }
    }

    /// Проверяет уровни логов
    public func testLogLevels() {
        if let tempDir {
            let logger = LogManagerSharedNDJSON(appGroupContainerURL: tempDir, maxLogCount: 10)
            logger.clearLogs()
            let fixedDate = Date(timeIntervalSince1970: 1_234_567_890)
            let entry = LogEntry(level: .warning, module: module, message: message, metadata: metadata, timestamp: fixedDate)
            logger.log(entry)
            let logs = logger.getLogs()
            expect(logs.first?.level).to(equal(.warning))
        } else {
            XCTFail("tempDir is nil")
        }
    }

    /// Проверяет производительность записи 1000 логов
    public func testPerformance1000Logs() {
        if let tempDir {
            let logger = LogManagerSharedNDJSON(appGroupContainerURL: tempDir, maxLogCount: 10)
            logger.clearLogs()
            let fixedDate = Date(timeIntervalSince1970: 1_234_567_890)
            let entry = LogEntry(level: .info, module: module, message: message, metadata: metadata, timestamp: fixedDate)
            measure {
                for _ in 0 ..< 10 {
                    logger.log(entry)
                }
            }
            expect(logger.getLogs().count).to(equal(10))
        } else {
            XCTFail("tempDir is nil")
        }
    }

    /// Очистка ресурсов (stub)
    deinit { /* nothing to cleanup */ }
}
