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
            promptTemplate: "Translate the following text to Russian: {text}",
            colorHex: "3288bd"
        )
        inventoryStub?.saveInventory([operation])
        viewModel?.loadInventory()
        XCTAssertEqual(self.viewModel?.operations, [operation])
    }

    public func testAddOperationAppendsToInventory() {
        let operation = InventoryOperation(
            operation: .simplify,
            params: try! JSONEncoder().encode(SimplifyParams(complexityLevel: .schoolchild)),
            promptTemplate: "Simplify the following text for a beginner reader: {text}",
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
            promptTemplate: "Correct grammar and spelling: {text}",
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
            params: try! JSONEncoder().encode(ExplainParams(detailLevel: .schoolchild)),
            promptTemplate: "Explain the following concept at beginner level: {text}",
            colorHex: "abdda4"
        )
        let operation2 = InventoryOperation(
            operation: .explain,
            params: try! JSONEncoder().encode(ExplainParams(detailLevel: .adult)),
            promptTemplate: "Explain the following concept at advanced level: {text}",
            colorHex: "5e4fa2"
        )
        inventoryStub?.saveInventory([operation1])
        viewModel?.loadInventory()
        viewModel?.updateOperation(at: 0, with: operation2)
        XCTAssertEqual(self.viewModel?.operations.first, operation2)
        XCTAssertEqual(self.inventoryStub?.inventory.first, operation2)
    }

    deinit {}
}
