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

    public func testLoadInventoryLoadsOperations() {
        let operation = InventoryOperation(
            operation: .translate,
            params: try! JSONEncoder().encode(TranslateParams(targetLanguage: "ru")),
            colorHex: "3288bd"
        )
        inventoryStub?.saveInventory([operation])
        viewModel?.loadInventory()
        XCTAssertEqual(self.viewModel?.operations, [operation])
    }

    public func testAddOperationAppendsToInventory() {
        let operation = InventoryOperation(
            operation: .simplify,
            params: try! JSONEncoder().encode(SimplifyParams()),
            colorHex: "fdae61"
        )
        viewModel?.addOperation(operation)
        XCTAssertTrue(self.viewModel?.operations.contains(operation) ?? false)
        XCTAssertTrue(self.inventoryStub?.inventory.contains(operation) ?? false)
    }

    public func testRemoveOperationRemovesFromInventory() {
        let operation = InventoryOperation(
            operation: .correct,
            params: try! JSONEncoder().encode(CorrectParams()),
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
            params: try! JSONEncoder().encode(ExplainParams()),
            colorHex: "abdda4"
        )
        let operation2 = InventoryOperation(
            operation: .explain,
            params: try! JSONEncoder().encode(ExplainParams()),
            colorHex: "5e4fa2"
        )
        inventoryStub?.saveInventory([operation1])
        viewModel?.loadInventory()
        viewModel?.updateOperation(at: 0, with: operation2)
        XCTAssertEqual(self.viewModel?.operations.first, operation2)
        XCTAssertEqual(self.inventoryStub?.inventory.first, operation2)
    }

    public func testReorderOperationsChangesOrder() {
        let operation1 = InventoryOperation(
            operation: .translate,
            params: try! JSONEncoder().encode(TranslateParams(targetLanguage: "en")),
            colorHex: "3288bd"
        )
        let operation2 = InventoryOperation(
            operation: .simplify,
            params: try! JSONEncoder().encode(SimplifyParams()),
            colorHex: "fdae61"
        )
        let operation3 = InventoryOperation(
            operation: .correct,
            params: try! JSONEncoder().encode(CorrectParams()),
            colorHex: "d53e4f"
        )
        inventoryStub?.saveInventory([operation1, operation2, operation3])
        viewModel?.loadInventory()
        // Перемещаем второй элемент (index 1) на первое место (index 0)
        viewModel?.reorderOperations(fromOffsets: IndexSet(integer: 1), toOffset: 0)
        let expected = [operation2, operation1, operation3]
        XCTAssertEqual(self.viewModel?.operations, expected)
        XCTAssertEqual(self.inventoryStub?.inventory, expected)
    }

    public func testDeleteOperationViaEditViewRemovesFromList() {
        // Arrange: добавляем три операции
        let operation1 = InventoryOperation(
            operation: .translate,
            params: try! JSONEncoder().encode(TranslateParams(targetLanguage: "en")),
            colorHex: "3288bd"
        )
        let operation2 = InventoryOperation(
            operation: .simplify,
            params: try! JSONEncoder().encode(SimplifyParams()),
            colorHex: "fdae61"
        )
        let operation3 = InventoryOperation(
            operation: .correct,
            params: try! JSONEncoder().encode(CorrectParams()),
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
