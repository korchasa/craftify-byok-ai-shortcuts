import Nimble
import SwiftUI
import XCTest
#if canImport(ViewInspector)
    @testable import CraftifyShared
    @testable import MainApp
    import ViewInspector

    public final class E2EInventoryFlowTests: XCTestCase {
        override public init() { super.init() }
        deinit {}
        public func testAddEditDeleteOperation() throws {
            let inventory = InventoryManagerStub()
            let homeVM = HomeViewModel(inventoryManager: inventory)
            let addVM = AddOperationViewModel()
            // Добавление операции
            addVM.selectedType = .translate
            addVM.targetLanguage = "ru"
            let op = addVM.makeOperation()
            expect(op) != nil
            homeVM.addOperation(op!)
            expect(homeVM.operations.count) == 1
            // Редактирование операции
            let editVM = EditOperationViewModel(operation: homeVM.operations[0])
            editVM.targetLanguage = "en"
            let updated = editVM.makeOperation()
            homeVM.updateOperation(at: 0, with: updated!)
            expect(homeVM.operations[0].operation) == .translate
            // Удаление операции
            homeVM.removeOperation(at: 0)
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
#endif
