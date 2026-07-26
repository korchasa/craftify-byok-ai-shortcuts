// @testable import Common
@testable import MainApp
import XCTest

public final class HomeViewModelTests: XCTestCase {
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

    public func testInitialInventoryIsEmpty() {
        XCTAssertNotNil(self.viewModel)
        XCTAssertTrue(self.viewModel?.operations.isEmpty ?? false)
    }

    public func testLoadInventoryLoadsOperations() throws {
        let operation = try InventoryOperation(
            operation: .translate,
            params: JSONEncoder().encode(TranslateParams(targetLanguage: "ru")),
            colorHex: "3288bd"
        )
        inventoryStub?.saveInventory([operation])
        viewModel?.loadInventory()
        XCTAssertEqual(self.viewModel?.operations, [operation])
    }

    public func testAddOperationAppendsToInventory() {
        let operation = InventoryOperation(
            operation: .simplify,
            params: Data(),
            colorHex: "fdae61"
        )
        viewModel?.addOperation(operation)
        XCTAssertTrue(self.viewModel?.operations.contains(operation) ?? false)
        XCTAssertTrue(self.inventoryStub?.inventory.contains(operation) ?? false)
    }

    public func testRemoveOperationRemovesFromInventory() {
        let operation = InventoryOperation(
            operation: .correct,
            params: Data(),
            colorHex: "d53e4f"
        )
        inventoryStub?.saveInventory([operation])
        viewModel?.loadInventory()
        viewModel?.removeOperation(at: 0)
        XCTAssertTrue(self.viewModel?.operations.isEmpty ?? false)
        XCTAssertTrue(self.inventoryStub?.inventory.isEmpty ?? false)
    }

    public func testUpdateOperationUpdatesInventory() {
        let operation1 = InventoryOperation(
            operation: .explain,
            params: Data(),
            colorHex: "abdda4"
        )
        let operation2 = InventoryOperation(
            operation: .explain,
            params: Data(),
            colorHex: "5e4fa2"
        )
        inventoryStub?.saveInventory([operation1])
        viewModel?.loadInventory()
        viewModel?.updateOperation(at: 0, with: operation2)
        XCTAssertEqual(self.viewModel?.operations.first, operation2)
        XCTAssertEqual(self.inventoryStub?.inventory.first, operation2)
    }

    public func testPlaceOperationSwapsTilesBetweenCells() throws {
        let operation1 = try InventoryOperation(
            operation: .translate,
            params: JSONEncoder().encode(TranslateParams(targetLanguage: "en")),
            colorHex: "3288bd",
            slot: 0
        )
        let operation2 = InventoryOperation(
            operation: .simplify,
            params: Data(),
            colorHex: "fdae61",
            slot: 1
        )
        inventoryStub?.saveInventory([operation1, operation2])
        viewModel?.loadInventory()
        // Кладём первую плитку на место второй — они меняются ячейками
        viewModel?.placeOperation(id: operation1.id, at: 1)
        XCTAssertEqual(self.viewModel?.operations.first { $0.id == operation1.id }?.slot, 1)
        XCTAssertEqual(self.viewModel?.operations.first { $0.id == operation2.id }?.slot, 0)
        XCTAssertEqual(self.inventoryStub?.inventory.first { $0.id == operation1.id }?.slot, 1)
    }

    public func testPlaceOperationMovesTileToAnEmptyCell() {
        let operation = InventoryOperation(operation: .correct, params: Data(), colorHex: "d53e4f", slot: 0)
        inventoryStub?.saveInventory([operation])
        viewModel?.loadInventory()
        viewModel?.placeOperation(id: operation.id, at: 5)
        XCTAssertEqual(self.viewModel?.operations.first?.slot, 5)
        XCTAssertEqual(self.viewModel?.firstFreeSlot, 0)
    }

    public func testDeleteOperationViaEditViewRemovesFromList() throws {
        // Arrange: добавляем три операции
        let operation1 = try InventoryOperation(
            operation: .translate,
            params: JSONEncoder().encode(TranslateParams(targetLanguage: "en")),
            colorHex: "3288bd"
        )
        let operation2 = InventoryOperation(
            operation: .simplify,
            params: Data(),
            colorHex: "fdae61"
        )
        let operation3 = InventoryOperation(
            operation: .correct,
            params: Data(),
            colorHex: "d53e4f"
        )
        inventoryStub?.saveInventory([operation1, operation2, operation3])
        viewModel?.loadInventory()
        // Act: удаляем вторую операцию (index 1)
        viewModel?.removeOperation(at: 1)
        // Assert: операция удалена из списка
        let expected = [operation1, operation3]
        XCTAssertEqual(self.viewModel?.operations, expected)
        XCTAssertEqual(self.inventoryStub?.inventory, expected)
    }

    deinit {}
}
