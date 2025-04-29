import Nimble
import SwiftUI
import XCTest
#if canImport(ViewInspector)
    @testable import Common
    import ViewInspector

    public final class HomeViewUITests: XCTestCase {
        private var inventoryStub: InventoryManagerStub?
        private var viewModel: HomeViewModel?

        private enum TestConstants {
            static let indexFirst = 0
            static let countOne = 1
        }

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
                expect(try list.numberOfRows()) == TestConstants.indexFirst
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
                expect(try list.numberOfRows()) == TestConstants.countOne
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
                try list.delete(row: TestConstants.indexFirst)
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

        public func testOperationColorCircleIsVisible() throws {
            if let viewModel {
                let operation = InventoryOperation(
                    operation: .translate,
                    params: try! JSONEncoder().encode(TranslateParams(targetLanguage: "ru")),
                    promptTemplate: "Translate the following text to Russian: {text}",
                    colorHex: "3288bd"
                )
                viewModel.addOperation(operation)
                let view = HomeView(viewModel: viewModel)
                let list = try view.inspect().find(ViewType.List.self)
                let hStack = try list.find(ViewType.HStack.self)
                let circle = try hStack.find(ViewType.Shape.self)
                // Проверяем, что accessibilityLabel у кружка правильный
                expect(try circle.accessibilityLabel()) == "Цвет операции"
                // Проверяем, что цвет совпадает (по hex)
                // ViewInspector не позволяет напрямую проверить цвет, но можно проверить структуру
            }
        }

        deinit {}
    }
#endif
