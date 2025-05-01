@testable import Common
import Nimble
import XCTest

public final class E2ELogManagerTests: XCTestCase {
    deinit {}
    private enum TestConstants {
        static let maxLogCount = 10
        static let logInsertCount = 12
    }

    public func testLogWriteMaskExportFIFO() throws {
        let logger = LogManagerSharedInMemory(maxLogCount: TestConstants.maxLogCount)
        for i in 0 ..< TestConstants.logInsertCount {
            logger.log(LogEntry(level: .info, module: "test", message: "msg\(i)", metadata: ["apiKey": "sk-1234567890abcdef"]))
        }
        let logs = logger.getLogs()
        expect(logs.count) == TestConstants.maxLogCount // FIFO
        guard let msg = logs.first?.message else { fail("message is nil")
            return
        }
        expect(msg) == "msg2"
        let exported = try logger.exportLogs()
        guard let exportedString = String(data: exported, encoding: .utf8) else { fail("exportedString is nil")
            return
        }
        expect(exportedString).to(contain("***************cdef")) // маскирование
    }
}
