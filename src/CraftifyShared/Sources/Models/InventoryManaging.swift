import Foundation

/// Протокол для менеджера inventory
public protocol InventoryManaging: AnyObject {
    var inventory: [InventoryOperation] { get }
    func loadInventory() -> [InventoryOperation]
    func saveInventory(_ inventory: [InventoryOperation])
    func addOperation(_ operation: InventoryOperation)
    func updateOperation(at index: Int, with operation: InventoryOperation)
    func removeOperation(at index: Int)
    func clearInventory()
}
