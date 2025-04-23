@testable import CraftifyShared
import Nimble
import XCTest

public final class E2ELogManagerTests: XCTestCase {
    deinit {}
    public func testLogWriteMaskExportFIFO() throws {
        let logger = LogManagerSharedInMemory(maxLogCount: 10)
        for i in 0 ..< 12 {
            logger.log(LogEntry(level: .info, module: "test", message: "msg\(i)", metadata: ["apiKey": "sk-1234567890abcdef"]))
        }
        let logs = logger.getLogs()
        expect(logs.count) == 10 // FIFO
        guard let msg = logs.first?.message else { fail("message is nil")
            return
        }
        expect(msg) == "msg2"
        let exported = try logger.exportLogs()
        guard let exportedString = String(data: exported, encoding: .utf8) else { fail("exportedString is nil")
            return
        }
        print("[DEBUG] Exported logs string:\n\(exportedString)")
        expect(exportedString).to(contain("***************cdef")) // маскирование
    }
}
