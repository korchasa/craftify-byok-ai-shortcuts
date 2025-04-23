@testable import CraftifyShared
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
            let op2 = InventoryOperation(operation: .simplify, params: try! JSONEncoder().encode(SimplifyParams(complexityLevel: .beginner)), promptTemplate: "S: {text}")
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
            let cancelButton = try view.inspect().find(button: "Отмена")
            expect(try cancelButton.accessibilityLabel()) == "Отмена"
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
    }
#endif
