@testable import Common
@testable import MainApp
import Nimble
import XCTest

@MainActor
public final class SettingsViewModelTests: XCTestCase {
    private var authManager: AuthManagerStub?
    private var viewModel: SettingsViewModel?

    override public func setUp() {
        super.setUp()
        authManager = AuthManagerStub(key: nil)
        viewModel = SettingsViewModel(authManager: authManager!)
    }

    override public func tearDown() {
        authManager = nil
        viewModel = nil
        super.tearDown()
    }

    public func testLoad_NoKey() async {
        guard let viewModel, let _ = authManager else { XCTFail("nil stub")
            return
        }
        await viewModel.load()
        expect(viewModel.apiKey) == ""
        expect(viewModel.isKeyPresent) == false
        expect(viewModel.maskedApiKey) == maskKey(nil)
    }

    public func testSaveKey_Valid() async {
        guard let viewModel, let _ = authManager else { XCTFail("nil stub")
            return
        }
        await MainActor.run { viewModel.apiKey = "sk-valid-key-1234567890" }
        await viewModel.saveKey()
        expect(viewModel.isKeyPresent) == true
        expect(viewModel.maskedApiKey) == maskKey("sk-valid-key-1234567890")
        expect(viewModel.errorMessage == nil) == true
    }

    public func testSaveKey_Invalid() async {
        guard let viewModel, let _ = authManager else { XCTFail("viewModel is nil")
            return
        }
        await MainActor.run { viewModel.apiKey = "short" }
        await viewModel.saveKey()
        expect(viewModel.isKeyPresent) == false
        expect(viewModel.errorMessage != nil) == true
    }

    public func testDeleteKey() async {
        guard let viewModel, let _ = authManager else { XCTFail("nil stub")
            return
        }
        await MainActor.run { viewModel.apiKey = "sk-valid-key-1234567890" }
        await viewModel.saveKey()
        await viewModel.deleteKey()
        expect(viewModel.isKeyPresent) == false
        expect(viewModel.apiKey) == ""
    }

    deinit {}
}
