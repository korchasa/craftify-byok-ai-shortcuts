@testable import CraftifyShared
import Nimble
import XCTest

/// Тесты для maskKey (маскирование API-ключа)
public final class MaskingTests: XCTestCase {
    deinit {}
    public func testMaskKey_NormalKey() {
        // Ключ длиннее минимального — маскируется, кроме последних 4 символов
        let key = "sk-1234567890abcdef"
        let masked = maskKey(key)
        expect(masked).to(equal("***************cdef"))
    }

    public func testMaskKey_ExactlyMinLength() {
        // Ключ ровно минимальной длины — полностью маскируется
        let key = String(repeating: "a", count: 8)
        let masked = maskKey(key)
        expect(masked).to(equal("********"))
    }

    public func testMaskKey_ShortKey() {
        // Ключ короче минимальной длины — полностью маскируется
        let key = "short"
        let masked = maskKey(key)
        expect(masked).to(equal("********"))
    }

    public func testMaskKey_NilKey() {
        // nil — полностью маскируется
        let masked = maskKey(nil)
        expect(masked).to(equal("********"))
    }
}
