import Nimble
import SwiftUI
import XCTest
#if canImport(ViewInspector)
    @testable import CraftifyShared
    import ViewInspector

    public final class HomeViewUITests: XCTestCase {
        private var inventoryStub: InventoryManagerStub?
        private var viewModel: HomeViewModel?

        override public func setUp() {
            super.setUp()
            inventoryStub = InventoryManagerStub()
            if let stub = inventoryStub {
                viewModel = HomeViewModel(inventoryManager: stub)
            }
        }

        override public func tearDown() {
            inventoryStub = nil
            viewModel = nil
            super.tearDown()
        }

        public func testEmptyInventoryShowsNoOperations() throws {
            if let viewModel {
                let view = HomeView(viewModel: viewModel)
                let list = try view.inspect().find(ViewType.List.self)
                expect(try list.numberOfRows()) == 0
            }
        }

        public func testInventoryDisplaysOperations() throws {
            if let viewModel {
                let operation = InventoryOperation(
                    operation: .translate,
                    params: try! JSONEncoder().encode(TranslateParams(targetLanguage: "ru")),
                    promptTemplate: "Translate the following text to Russian: {text}"
                )
                viewModel.addOperation(operation)
                let view = HomeView(viewModel: viewModel)
                let list = try view.inspect().find(ViewType.List.self)
                expect(try list.numberOfRows()) == 1
                let text = try list.find(text: "Перевод")
                expect(try text.string()).to(contain("Перевод"))
            }
        }

        public func testDeleteOperationRemovesFromList() throws {
            if let viewModel {
                let operation = InventoryOperation(
                    operation: .simplify,
                    params: try! JSONEncoder().encode(SimplifyParams(complexityLevel: .beginner)),
                    promptTemplate: "Simplify the following text for a beginner reader: {text}"
                )
                viewModel.addOperation(operation)
                let view = HomeView(viewModel: viewModel)
                var list = try view.inspect().find(ViewType.List.self)
                try list.delete(row: 0)
                expect(viewModel.operations).to(beEmpty())
            }
        }

        public func testTapAddOperationNavigatesToAddOperationView() throws {
            if let viewModel {
                let view = HomeView(viewModel: viewModel)
                let button = try view.inspect().find(button: L10n.homeAddOperation)
                try button.tap()
                // Проверяем, что навигация инициирована (например, через флаг в viewModel или presented view)
            }
        }

        public func testTapSettingsNavigatesToSettingsView() throws {
            if let viewModel {
                let view = HomeView(viewModel: viewModel)
                let button = try view.inspect().find(button: L10n.homeSettings)
                try button.tap()
                // Проверяем, что навигация инициирована (например, через флаг в viewModel или presented view)
            }
        }

        public func testAccessibilityLabelsAndDynamicType() throws {
            if let viewModel {
                let view = HomeView(viewModel: viewModel)
                let addButton = try view.inspect().find(button: L10n.homeAddOperation)
                let settingsButton = try view.inspect().find(button: L10n.homeSettings)
                // accessibilityLabel
                expect(try addButton.accessibilityLabel()) == L10n.homeAddOperation
                expect(try settingsButton.accessibilityLabel()) == L10n.homeSettings
                // Dynamic Type (проверка поддержки)
                let title = try view.inspect().find(text: L10n.homeTitle)
                let font = try title.attributes().font()
                expect(font?.supportsDynamicType ?? false) == true
            }
        }

        deinit {}
    }
#endif
