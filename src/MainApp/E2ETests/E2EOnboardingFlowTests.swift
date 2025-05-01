import Nimble
import SwiftUI
import XCTest
#if canImport(ViewInspector)
    @testable import Common
    @testable import MainApp
    import ViewInspector

    public final class E2EOnboardingFlowTests: XCTestCase {
        override public init() { super.init() }
        deinit {}
        public func testOnboardingConsentFlow() throws {
            let consentManager = ConsentManagerStub()
            let appState = AppState(consentManager: consentManager)
            // Изначально согласие не дано
            XCTAssertFalse(appState.isConsentGiven)
            // Показывается HowToUseView
            var didConsent = false
            let view = HowToUseView(consentManager: consentManager, onConsent: {
                didConsent = true
                appState.setConsentGiven(true)
            })
            let button = try view.inspect().find(button: L10n.howtouseDone)
            expect(try button.isDisabled()) == true
            try view.inspect().find(ViewType.Toggle.self).setIsOn(true)
            expect(try button.isDisabled()) == false
            try button.tap()
            expect(consentManager.getConsent()) == true
            expect(didConsent) == true
            // После согласия appState.isConsentGiven становится true
            XCTAssertTrue(appState.isConsentGiven)
        }
    }

    extension HowToUseView: Inspectable {}
#endif
