import Nimble
import SwiftUI
import XCTest
#if canImport(ViewInspector)
    @testable import Common
    @testable import MainApp
    import ViewInspector

    public final class E2EInventoryFlowTests: XCTestCase {
        override public init() { super.init() }
        deinit {}
        private enum TestConstants {
            static let indexFirst = 0
            static let countOne = 1
        }

        public func testAddEditDeleteOperation() throws {
            let inventory = InventoryManagerStub()
            let homeVM = HomeViewModel(inventoryManager: inventory)
            let addVM = AddOperationViewModel()
            // Добавление операции
            addVM.selectedType = .translate
            addVM.targetLanguage = "ru"
            let op = addVM.makeOperation()?.copyWithColor("3288bd")
            expect(op) != nil
            homeVM.addOperation(op!)
            expect(homeVM.operations.count) == TestConstants.countOne
            // Редактирование операции
            let editVM = EditOperationViewModel(operation: homeVM.operations[TestConstants.indexFirst])
            editVM.targetLanguage = "en"
            let updated = editVM.makeOperation()?.copyWithColor("d53e4f")
            homeVM.updateOperation(at: TestConstants.indexFirst, with: updated!)
            expect(homeVM.operations[TestConstants.indexFirst].operation) == .translate
            // Удаление операции
            homeVM.removeOperation(at: TestConstants.indexFirst)
            expect(homeVM.operations.isEmpty) == true
        }

        public func testAddInvalidOperation() {
            let addVM = AddOperationViewModel()
            addVM.selectedType = .translate
            addVM.targetLanguage = ""
            expect(addVM.isValid) == false
            let op = addVM.makeOperation()
            expect(op) == nil
        }
    }

    // Вспомогательный extension для копирования операции с цветом
    extension InventoryOperation {
        func copyWithColor(_ color: String) -> InventoryOperation {
            InventoryOperation(operation: self.operation, params: self.params, promptTemplate: self.promptTemplate, colorHex: color)
        }
    }
#endif
