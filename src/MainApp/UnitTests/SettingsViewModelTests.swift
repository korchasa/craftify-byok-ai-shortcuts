// @testable import Common
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
        XCTAssertEqual(viewModel.apiKey, "")
        XCTAssertFalse(viewModel.isKeyPresent)
        XCTAssertEqual(viewModel.maskedApiKey, maskKey(nil))
    }

    public func testSaveKey_Valid() async {
        guard let viewModel, let _ = authManager else { XCTFail("nil stub")
            return
        }
        await MainActor.run { viewModel.apiKey = "sk-valid-key-1234567890" }
        await viewModel.saveKey()
        XCTAssertTrue(viewModel.isKeyPresent)
        XCTAssertEqual(viewModel.maskedApiKey, maskKey("sk-valid-key-1234567890"))
        XCTAssertNil(viewModel.errorMessage)
    }

    public func testSaveKey_Invalid() async {
        guard let viewModel, let _ = authManager else { XCTFail("viewModel is nil")
            return
        }
        await MainActor.run { viewModel.apiKey = "short" }
        await viewModel.saveKey()
        XCTAssertFalse(viewModel.isKeyPresent)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    public func testDeleteKey() async {
        guard let viewModel, let _ = authManager else { XCTFail("nil stub")
            return
        }
        await MainActor.run { viewModel.apiKey = "sk-valid-key-1234567890" }
        await viewModel.saveKey()
        await viewModel.deleteKey()
        XCTAssertFalse(viewModel.isKeyPresent)
        XCTAssertEqual(viewModel.apiKey, "")
    }

    deinit {}
}
