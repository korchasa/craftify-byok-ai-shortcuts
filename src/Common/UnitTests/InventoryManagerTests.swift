// import Common
import XCTest

/// Тесты для InventoryManager
public final class InventoryManagerTests: XCTestCase {
    /// Проверяет добавление и загрузку операции
    public func testAddAndLoadOperation() {
        let manager = InventoryManagerStub()
        let operation = InventoryOperation(operation: .translate, params: Data(), colorHex: "3288bd")
        manager.addOperation(operation)
        XCTAssertEqual(manager.inventory.count, 1)
        XCTAssertEqual(manager.loadInventory().first?.operation, .translate)
    }

    /// Проверяет обновление операции
    public func testUpdateOperation() {
        let manager = InventoryManagerStub()
        let operation1 = InventoryOperation(operation: .translate, params: Data(), colorHex: "3288bd")
        let operation2 = InventoryOperation(operation: .simplify, params: Data(), colorHex: "d53e4f")
        manager.addOperation(operation1)
        manager.updateOperation(at: 0, with: operation2)
        XCTAssertEqual(manager.inventory.first?.operation, .simplify)
    }

    /// Проверяет удаление операции
    public func testRemoveOperation() {
        let manager = InventoryManagerStub()
        let operation = InventoryOperation(operation: .translate, params: Data(), colorHex: "3288bd")
        manager.addOperation(operation)
        manager.removeOperation(at: 0)
        XCTAssertTrue(manager.inventory.isEmpty)
    }

    /// Проверяет очистку инвентаря
    public func testClearInventory() {
        let manager = InventoryManagerStub()
        manager.addOperation(InventoryOperation(operation: .translate, params: Data(), colorHex: "3288bd"))
        manager.clearInventory()
        XCTAssertTrue(manager.inventory.isEmpty)
    }

    /// Проверяет сохранение и загрузку инвентаря
    public func testSaveAndLoadInventory() {
        let manager = InventoryManagerStub()
        let operation = InventoryOperation(operation: .translate, params: Data(), colorHex: "3288bd")
        manager.saveInventory([operation])
        let loaded = manager.loadInventory()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.operation, .translate)
    }

    deinit {
        // Очистка ресурсов не требуется
    }
}
