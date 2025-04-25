@testable import Common
import Nimble
import XCTest

/// Тесты для InventoryManager
public final class InventoryManagerTests: XCTestCase {
    /// Проверяет добавление и загрузку операции
    public func testAddAndLoadOperation() {
        let manager = InventoryManagerStub()
        let operation = InventoryOperation(operation: .translate, params: Data(), promptTemplate: "template")
        manager.addOperation(operation)
        expect(manager.inventory.count) == 1
        expect(manager.loadInventory().first?.operation) == .translate
    }

    /// Проверяет обновление операции
    public func testUpdateOperation() {
        let manager = InventoryManagerStub()
        let operation1 = InventoryOperation(operation: .translate, params: Data(), promptTemplate: "t1")
        let operation2 = InventoryOperation(operation: .simplify, params: Data(), promptTemplate: "t2")
        manager.addOperation(operation1)
        manager.updateOperation(at: 0, with: operation2)
        expect(manager.inventory.first?.operation) == .simplify
    }

    /// Проверяет удаление операции
    public func testRemoveOperation() {
        let manager = InventoryManagerStub()
        let operation = InventoryOperation(operation: .translate, params: Data(), promptTemplate: "t")
        manager.addOperation(operation)
        manager.removeOperation(at: 0)
        expect(manager.inventory.isEmpty) == true
    }

    /// Проверяет очистку инвентаря
    public func testClearInventory() {
        let manager = InventoryManagerStub()
        manager.addOperation(InventoryOperation(operation: .translate, params: Data(), promptTemplate: "t"))
        manager.clearInventory()
        expect(manager.inventory.isEmpty) == true
    }

    /// Проверяет сохранение и загрузку инвентаря
    public func testSaveAndLoadInventory() {
        let manager = InventoryManagerStub()
        let operation = InventoryOperation(operation: .translate, params: Data(), promptTemplate: "t")
        manager.saveInventory([operation])
        let loaded = manager.loadInventory()
        expect(loaded.count) == 1
        expect(loaded.first?.operation) == .translate
    }

    deinit {
        // Очистка ресурсов не требуется
    }
}
