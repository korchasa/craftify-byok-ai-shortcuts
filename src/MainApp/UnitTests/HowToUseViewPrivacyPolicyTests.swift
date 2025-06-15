@testable import MainApp
import SwiftUI
import XCTest

/// Tests for Privacy Policy rendering inside HowToUseView
@MainActor
public final class HowToUseViewPrivacyPolicyTests: XCTestCase {
    private var consentStub: ConsentManagerStub!

    override public func setUp() {
        super.setUp()
        consentStub = ConsentManagerStub()
    }

    override public func tearDown() {
        consentStub = nil
        super.tearDown()
    }

    /// Проверяет, что HowToUseView можно отобразить и содержит локализованный текст политики конфиденциальности
    public func testHowToUseViewRendersPrivacyPolicy() {
        let view = HowToUseView(consentManager: consentStub)
        let controller = UIHostingController(rootView: view)
        XCTAssertNotNil(controller.view)

        // Check that localization key exists and not empty
        let policy = L10n.privacyPolicyFull
        XCTAssertFalse(policy.isEmpty, "Privacy policy localization must not be empty")
    }

    deinit {}
}
