@testable import CraftifyShared
@testable import MainApp
import Nimble
import XCTest

@MainActor
public final class SettingsViewModelTests: XCTestCase {
    private var authManager: AuthManagerStub?
    private var consentManager: ConsentManagerStub?
    private var viewModel: SettingsViewModel?

    override public func setUp() {
        super.setUp()
        authManager = AuthManagerStub(key: nil)
        consentManager = ConsentManagerStub()
        viewModel = SettingsViewModel(authManager: authManager!, consentManager: consentManager!)
    }

    override public func tearDown() {
        authManager = nil
        consentManager = nil
        viewModel = nil
        super.tearDown()
    }

    public func testLoad_NoKey() async {
        guard let viewModel, let authManager else { XCTFail("nil stub")
            return
        }
        await viewModel.load()
        await expect { try await viewModel.apiKey } == ""
        await expect { try await viewModel.isKeyPresent } == false
        await expect { try await viewModel.maskedApiKey } == maskKey(nil)
    }

    public func testSaveKey_Valid() async {
        guard let viewModel, let authManager else { XCTFail("nil stub")
            return
        }
        await MainActor.run { viewModel.apiKey = "sk-valid-key-1234567890" }
        await viewModel.saveKey()
        expect(authManager.savedKey) == "sk-valid-key-1234567890"
        await expect { try await viewModel.isKeyPresent } == true
        await expect { try await viewModel.maskedApiKey } == maskKey("sk-valid-key-1234567890")
        await expect { try await viewModel.errorMessage == nil } == true
    }

    public func testSaveKey_Invalid() async {
        guard let viewModel, let authManager else { XCTFail("viewModel is nil")
            return
        }
        await MainActor.run { viewModel.apiKey = "short" }
        await viewModel.saveKey()
        expect(authManager.savedKey == nil) == true
        await expect { try await viewModel.isKeyPresent } == false
        await expect { try await viewModel.errorMessage != nil } == true
    }

    public func testDeleteKey() async {
        guard let viewModel, let authManager else { XCTFail("nil stub")
            return
        }
        await MainActor.run { viewModel.apiKey = "sk-valid-key-1234567890" }
        await viewModel.saveKey()
        await viewModel.deleteKey()
        expect(authManager.savedKey == nil) == true
        await expect { try await viewModel.isKeyPresent } == false
        await expect { try await viewModel.apiKey } == ""
    }

    public func testConsent() async {
        guard let viewModel, let consentManager else { XCTFail("viewModel is nil")
            return
        }
        await expect { try await viewModel.consentGiven } == false
        await MainActor.run { viewModel.setConsent(true) }
        expect(consentManager.getConsent()) == true
        await expect { try await viewModel.consentGiven } == true
    }

    deinit {}
}
