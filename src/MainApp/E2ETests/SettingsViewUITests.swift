@testable import Common
@testable import MainApp
import Nimble
import SwiftUI
import XCTest
#if canImport(ViewInspector)
    import ViewInspector

    public final class SettingsViewUITests: XCTestCase {
        private var authManager: AuthManagerStub?
        private var consentManager: ConsentManagerStub?
        private var viewModel: SettingsViewModel?

        override public func setUp() {
            super.setUp()
            authManager = AuthManagerStub()
            consentManager = ConsentManagerStub()
            viewModel = SettingsViewModel(authManager: authManager!, consentManager: consentManager!)
        }

        override public func tearDown() {
            authManager = nil
            consentManager = nil
            viewModel = nil
            super.tearDown()
        }

        public func testInitialState_NoKey() throws {
            guard let viewModel else { XCTFail("viewModel is nil")
                return
            }
            let view = SettingsView(viewModel: viewModel)
            let textField = try view.inspect().find(ViewType.SecureField.self)
            expect(try textField.text()) == ""
        }

        public func testSaveKeyButtonEnabledWhenValid() throws {
            guard let viewModel else { XCTFail("viewModel is nil")
                return
            }
            viewModel.apiKey = "sk-valid-key-1234567890"
            let view = SettingsView(viewModel: viewModel)
            let button = try view.inspect().find(button: "Сохранить")
            expect(try button.isDisabled()) == false
        }

        public func testSaveKeyButtonDisabledWhenEmpty() throws {
            guard let viewModel else { XCTFail("viewModel is nil")
                return
            }
            viewModel.apiKey = ""
            let view = SettingsView(viewModel: viewModel)
            let button = try view.inspect().find(button: "Сохранить")
            expect(try button.isDisabled()) == true
        }

        public func testDeleteKeyButtonAppearsWhenKeyPresent() throws {
            guard let authManager, let viewModel else { XCTFail("nil stub")
                return
            }
            authManager.savedKey = "sk-valid-key-1234567890"
            Task { await viewModel.load() }
            let view = SettingsView(viewModel: viewModel)
            let deleteButton = try? view.inspect().find(button: "Удалить")
            expect(deleteButton != nil) == true
        }

        public func testErrorMessageShown() throws {
            guard let viewModel else { XCTFail("viewModel is nil")
                return
            }
            viewModel.errorMessage = "Ошибка!"
            let view = SettingsView(viewModel: viewModel)
            let text = try view.inspect().find(text: "Ошибка!")
            expect(try text.string()) == "Ошибка!"
        }

        public func testAccessibilityLabelsAndDynamicType() throws {
            guard let viewModel else { XCTFail("viewModel is nil")
                return
            }
            let view = SettingsView(viewModel: viewModel)
            let textField = try view.inspect().find(ViewType.SecureField.self)
            let saveButton = try view.inspect().find(button: "Сохранить")
            // accessibilityLabel
            expect(try textField.accessibilityLabel()) == L10n.settingsApiKey
            expect(try saveButton.accessibilityLabel()) == "Сохранить ключ"
            // Dynamic Type (проверка поддержки)
            let title = try view.inspect().find(text: L10n.settingsTitle)
            let font = try title.attributes().font()
            expect(font?.supportsDynamicType ?? false) == true
        }

        deinit {}
    }

    extension SettingsView: Inspectable {}
#endif
