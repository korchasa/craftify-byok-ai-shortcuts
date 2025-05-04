// import Common
import XCTest

/// Тесты для ConsentManager
public final class ConsentManagerTests: XCTestCase {
    /// Проверяет установку и получение согласия
    public func testSetAndGetConsent() {
        let manager = ConsentManagerStub()
        XCTAssertFalse(manager.getConsent())
        manager.setConsent(true)
        XCTAssertTrue(manager.getConsent())
    }

    /// Проверяет очистку согласия
    public func testClearConsent() {
        let manager = ConsentManagerStub()
        manager.setConsent(true)
        manager.clearConsent()
        XCTAssertFalse(manager.getConsent())
    }

    deinit {
        // Очистка ресурсов не требуется
    }
}
