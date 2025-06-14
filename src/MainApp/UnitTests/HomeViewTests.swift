@testable import MainApp
import SwiftUI
import XCTest

/// Тесты для HomeView (экран списка операций)
@MainActor
public final class HomeViewTests: XCTestCase {
    private var inventoryStub: InventoryManagerStub!
    private var viewModel: HomeViewModel!

    override public func setUp() {
        super.setUp()
        inventoryStub = InventoryManagerStub()
        viewModel = HomeViewModel(inventoryManager: inventoryStub)
    }

    override public func tearDown() {
        inventoryStub = nil
        viewModel = nil
        super.tearDown()
    }

    /// Проверяет, что HomeView успешно создаётся в UIHostingController
    public func testHomeViewRendersMainElements() {
        let view = HomeView(viewModel: viewModel)
        let controller = UIHostingController(rootView: view)
        XCTAssertNotNil(controller.view)
    }

    deinit {}
}
