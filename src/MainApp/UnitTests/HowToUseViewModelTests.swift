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

    public func testCompleteOnboarding_WithoutKeyGivesConsent() async {
        let stub = ConsentManagerStub()
        let authManager = AuthManagerStub(key: nil)
        let viewModel = HowToUseViewModel(consentManager: stub, authManager: authManager, verifier: APIKeyVerifierStub())
        let done = await viewModel.completeOnboarding()
        XCTAssertTrue(done)
        XCTAssertTrue(stub.getConsent())
    }

    public func testCompleteOnboarding_WithValidKeySavesIt() async {
        let stub = ConsentManagerStub()
        let authManager = AuthManagerStub(key: nil)
        let viewModel = HowToUseViewModel(consentManager: stub, authManager: authManager, verifier: APIKeyVerifierStub())
        await MainActor.run { viewModel.apiKey = "sk-valid-key-1234567890" }
        let done = await viewModel.completeOnboarding()
        XCTAssertTrue(done)
        XCTAssertTrue(stub.getConsent())
        let savedKey = try? await authManager.getAPIKey()
        XCTAssertEqual(savedKey, "sk-valid-key-1234567890")
    }

    public func testCompleteOnboarding_RejectedKeyBlocksContinue() async {
        let stub = ConsentManagerStub()
        let authManager = AuthManagerStub(key: nil)
        let viewModel = HowToUseViewModel(
            consentManager: stub,
            authManager: authManager,
            verifier: APIKeyVerifierStub(outcome: .invalid)
        )
        await MainActor.run { viewModel.apiKey = "sk-wrong-key-1234567890" }
        let done = await viewModel.completeOnboarding()
        XCTAssertFalse(done)
        XCTAssertFalse(stub.getConsent())
        XCTAssertNotNil(viewModel.errorMessage)
    }

    deinit {}
}
