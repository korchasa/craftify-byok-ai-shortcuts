// @testable import Common
import XCTest

public final class HowToUseViewModelTests: XCTestCase {
    public func testInitialConsentIsFalseByDefault() {
        let stub = ConsentManagerStub()
        let viewModel = HowToUseViewModel(consentManager: stub)
        XCTAssertFalse(viewModel.consentGiven)
    }

    public func testSetConsentUpdatesValue() {
        let stub = ConsentManagerStub()
        let viewModel = HowToUseViewModel(consentManager: stub)
        viewModel.consentGiven = true
        XCTAssertTrue(viewModel.consentGiven)
    }

    public func testSaveConsentPersistsValue() {
        let stub = ConsentManagerStub()
        let viewModel = HowToUseViewModel(consentManager: stub)
        viewModel.consentGiven = true
        viewModel.saveConsent()
        XCTAssertTrue(stub.getConsent())
    }

    public func testSaveConsentPersistsFalse() {
        let stub = ConsentManagerStub()
        stub.setConsent(true)
        let viewModel = HowToUseViewModel(consentManager: stub)
        viewModel.consentGiven = false
        viewModel.saveConsent()
        XCTAssertFalse(stub.getConsent())
    }

    deinit {}
}
