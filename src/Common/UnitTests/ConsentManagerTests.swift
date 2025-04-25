@testable import Common
import Nimble
import XCTest

/// Тесты для ConsentManager
public final class ConsentManagerTests: XCTestCase {
    /// Проверяет установку и получение согласия
    public func testSetAndGetConsent() {
        let manager = ConsentManagerStub()
        expect(manager.getConsent()) == false
        manager.setConsent(true)
        expect(manager.getConsent()) == true
    }

    /// Проверяет очистку согласия
    public func testClearConsent() {
        let manager = ConsentManagerStub()
        manager.setConsent(true)
        manager.clearConsent()
        expect(manager.getConsent()) == false
    }

    deinit {
        // Очистка ресурсов не требуется
    }
}
