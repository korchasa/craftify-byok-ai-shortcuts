@testable import CraftifyShared
@testable import MainApp
import Nimble
import SwiftUI
import XCTest
#if canImport(ViewInspector)
    import ViewInspector

    public final class HowToUseViewUITests: XCTestCase {
        public func testDoneButtonDisabledWhenConsentNotGiven() throws {
            let stub = ConsentManagerStub()
            let view = HowToUseView(consentManager: stub)
            let button = try view.inspect().find(button: L10n.howtouseDone)
            expect(try button.isDisabled()) == true
        }

        public func testDoneButtonEnabledWhenConsentGiven() throws {
            let stub = ConsentManagerStub()
            stub.setConsent(true)
            let view = HowToUseView(consentManager: stub)
            let button = try view.inspect().find(button: L10n.howtouseDone)
            expect(try button.isDisabled()) == false
        }

        public func testLocalizedStringsPresent() throws {
            let stub = ConsentManagerStub()
            let view = HowToUseView(consentManager: stub)
            let text = try view.inspect().find(text: L10n.howtouseTitle)
            expect(try text.string()) == L10n.howtouseTitle
        }

        public deinit {}
    }

    extension HowToUseView: Inspectable {}
#endif
