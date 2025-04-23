@testable import CraftifyShared
@testable import MainApp
import Nimble
import XCTest

public final class HowToUseViewModelTests: XCTestCase {
    public func testInitialConsentIsFalseByDefault() {
        let stub = ConsentManagerStub()
        let viewModel = HowToUseViewModel(consentManager: stub)
        expect(viewModel.consentGiven) == false
    }

    public func testSetConsentUpdatesValue() {
        let stub = ConsentManagerStub()
        let viewModel = HowToUseViewModel(consentManager: stub)
        viewModel.consentGiven = true
        expect(viewModel.consentGiven) == true
    }

    public func testSaveConsentPersistsValue() {
        let stub = ConsentManagerStub()
        let viewModel = HowToUseViewModel(consentManager: stub)
        viewModel.consentGiven = true
        viewModel.saveConsent()
        expect(stub.getConsent()) == true
    }

    public func testSaveConsentPersistsFalse() {
        let stub = ConsentManagerStub()
        stub.setConsent(true)
        let viewModel = HowToUseViewModel(consentManager: stub)
        viewModel.consentGiven = false
        viewModel.saveConsent()
        expect(stub.getConsent()) == false
    }

    deinit {}
}
