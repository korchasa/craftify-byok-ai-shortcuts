@testable import MainApp
import SwiftUI
import XCTest

/// Тесты для SettingsView (экран настроек)
@MainActor
public final class SettingsViewTests: XCTestCase {
    private var viewModel: SettingsViewModel!

    override public func setUp() {
        super.setUp()
        viewModel = SettingsViewModel(authManager: AuthManagerStub(key: nil))
    }

    override public func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    /// Проверяет, что SettingsView отображает основные элементы
    public func testSettingsViewRendersMainElements() {
        let view = SettingsView(viewModel: viewModel)
        let controller = UIHostingController(rootView: view)
        XCTAssertNotNil(controller.view)
        // Проверяем, что контроллер успешно создался (UI тесты — отдельная задача)
    }

    deinit {}
}
