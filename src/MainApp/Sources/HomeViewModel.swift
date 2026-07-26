import Foundation

public final class HomeViewModel: ObservableObject {
    @Published public private(set) var operations: [InventoryOperation] = []
    private let inventoryManager: InventoryManaging

    public init(inventoryManager: InventoryManaging) {
        self.inventoryManager = inventoryManager
        loadInventory()
    }

    public func loadInventory() {
        operations = inventoryManager.loadInventory()
    }

    public func addOperation(_ operation: InventoryOperation) {
        inventoryManager.addOperation(operation)
        loadInventory()
    }

    public func removeOperation(at index: Int) {
        inventoryManager.removeOperation(at: index)
        loadInventory()
    }

    public func updateOperation(at index: Int, with operation: InventoryOperation) {
        inventoryManager.updateOperation(at: index, with: operation)
        loadInventory()
    }

    /// Ставит плитку в указанную ячейку сетки. Занятая ячейка меняется местами
    /// с переносимой — плитку можно положить куда угодно, а не только сдвинуть
    /// соседей, как это было со списком
    public func placeOperation(id: UUID, at slot: Int) {
        inventoryManager.saveInventory(OperationGrid.place(operations, id: id, at: slot))
        loadInventory()
    }

    /// Первая свободная ячейка — туда встаёт операция, добавленная нижней кнопкой
    public var firstFreeSlot: Int {
        OperationGrid.firstFreeSlot(in: operations)
    }

    deinit {}
}
