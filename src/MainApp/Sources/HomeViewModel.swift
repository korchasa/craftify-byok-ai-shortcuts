import Common
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

    deinit {}
}
