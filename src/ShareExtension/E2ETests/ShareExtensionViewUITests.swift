@testable import Common
import Nimble
@testable import ShareExtension
import SwiftUI
import XCTest
#if canImport(ViewInspector)
    import ViewInspector

    public final class ShareExtensionViewUITests: XCTestCase {
        override public init() { super.init() }
        deinit {}
        private func makeViewModel() -> ShareExtensionViewModel {
            let inventory = InventoryManagerStub()
            let op1 = InventoryOperation(operation: .translate, params: try! JSONEncoder().encode(TranslateParams(targetLanguage: "ru")), promptTemplate: "T: {text}")
            let op2 = InventoryOperation(operation: .simplify, params: try! JSONEncoder().encode(SimplifyParams(complexityLevel: .schoolchild)), promptTemplate: "S: {text}")
            inventory.saveInventory([op1, op2])
            let manager = ShareExtensionManager(
                inventoryManager: inventory,
                authManager: AuthManagerStub(),
                clipboardManager: ClipboardManagerStub(),
                processingManager: ProcessingManagerStub(),
                consentManager: ConsentManagerStub()
            )
            manager.inputText = "Hello"
            return ShareExtensionViewModel(manager: manager)
        }

        public func testAccessibilityLabelsAndDynamicType() throws {
            let vm = makeViewModel()
            let view = ShareExtensionView(viewModel: vm)
            let grid = try view.inspect().find(ViewType.LazyVGrid.self)
            let buttons = try grid.findAll(ViewType.Button.self)
            expect(buttons.count) == 2
            expect(try buttons[0].accessibilityLabel()) == vm.operations[0].displayName
            expect(try buttons[1].accessibilityLabel()) == vm.operations[1].displayName
            let closeButtonsInGrid = try grid.findAll(ViewType.Button.self, where: { try $0.accessibilityIdentifier() == "closeButton" })
            expect(closeButtonsInGrid.count) == 0
            let title = try view.inspect().find(text: "Craftify — Обработка текста")
            let font = try title.attributes().font()
            expect(font?.supportsDynamicType ?? false) == true
        }

        public func testProgressOverlayAccessibility() throws {
            let vm = makeViewModel()
            vm.isProcessing = true
            vm.progress = 0.6
            let view = ShareExtensionView(viewModel: vm)
            let overlay = try view.inspect().find(ViewType.VStack.self, where: { v in
                (try? v.find(text: "Обработка...")) != nil
            })
            let label = try overlay.accessibilityLabel().string()
            expect(label).to(contain("прогресс 60%"))
        }

        public func testAlertShownOnError() throws {
            let vm = makeViewModel()
            let view = ShareExtensionView(viewModel: vm)
            vm.errorMessage = "Ошибка теста"
            let alert = try view.inspect().find(ViewType.Alert.self)
            expect(try alert.title().string()) == "Ошибка"
            expect(try alert.message().string()) == "Ошибка теста"
        }

        public func testCloseButtonExistsAndAction() throws {
            let vm = makeViewModel()
            vm.shouldCloseExtension = false
            let view = ShareExtensionView(viewModel: vm)
            let closeButton = try view.inspect().find(ViewType.Button.self, where: { try $0.accessibilityIdentifier() == "closeButton" })
            XCTAssertFalse(vm.shouldCloseExtension)
            try closeButton.tap()
            XCTAssertTrue(vm.shouldCloseExtension)
        }

        public func testOperationCardsHaveEqualHeight() throws {
            let vm = makeViewModel()
            let view = ShareExtensionView(viewModel: vm)
            let grid = try view.inspect().find(ViewType.LazyVGrid.self)
            let buttons = try grid.findAll(ViewType.Button.self)
            let heights = try buttons.map { try $0.actualView().frame(in: .local).height }
            XCTAssertTrue(heights.allSatisfy { $0 == heights.first })
        }

        public func testViewHeightDependsOnContent() throws {
            let vm = makeViewModel()
            let view = ShareExtensionView(viewModel: vm)
            let vStack = try view.inspect().find(ViewType.VStack.self)
            let height = try vStack.actualView().frame(in: .local).height
            // Проверяем, что высота не превышает разумный лимит (например, 400)
            XCTAssertLessThan(height, 400)
        }

        public func testOperationColorCircleIsVisible() throws {
            let vm = makeViewModel()
            // Присваиваем разный цвет операциям
            vm.operations[0] = InventoryOperation(operation: .translate, params: try! JSONEncoder().encode(TranslateParams(targetLanguage: "ru")), promptTemplate: "T: {text}", colorHex: "3288bd")
            vm.operations[1] = InventoryOperation(operation: .simplify, params: try! JSONEncoder().encode(SimplifyParams(complexityLevel: .schoolchild)), promptTemplate: "S: {text}", colorHex: "d53e4f")
            let view = ShareExtensionView(viewModel: vm)
            let grid = try view.inspect().find(ViewType.LazyVGrid.self)
            let buttons = try grid.findAll(ViewType.Button.self)
            for button in buttons {
                let hStack = try button.labelView().hStack()
                let circle = try hStack.find(ViewType.Shape.self)
                expect(try circle.accessibilityLabel()) == "Цвет операции"
                // Проверить hex напрямую нельзя, но структура есть
            }
        }

        public func testSheetDetentOrPopoverHeightIsSet() throws {
            // Проверяем, что высота ограничивается через detents или preferredContentSize
            let viewController = ShareExtensionViewController()
            viewController.loadViewIfNeeded()
            let operationsCount = viewController.hostingController?.rootView.viewModel.operations.count ?? 0
            let expectedHeight = ShareExtensionViewHeight.calculate(count: operationsCount)
            if #available(iOS 16.0, *) {
                if let sheet = viewController.sheetPresentationController {
                    let detents = sheet.detents
                    XCTAssertEqual(detents.count, 1)
                    if case let .custom(identifier, resolver) = detents.first! {
                        XCTAssertEqual(identifier.rawValue, "fixedHeight")
                        XCTAssertEqual(resolver(nil), expectedHeight)
                    }
                }
            } else if UIDevice.current.userInterfaceIdiom == .pad {
                XCTAssertEqual(viewController.preferredContentSize.height, expectedHeight)
            } else {
                // Для iPhone < iOS 15 — preferredContentSize выставлен, но система может игнорировать
                XCTAssertEqual(viewController.preferredContentSize.height, expectedHeight)
            }
        }
    }
#endif
