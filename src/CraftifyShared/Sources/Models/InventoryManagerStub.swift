import Foundation

/// In-memory stub для InventoryManaging (используется в тестах).
public final class InventoryManagerStub: InventoryManaging {
    public private(set) var inventory: [InventoryOperation] = []

    public init() {}

    /// Возвращает текущий инвентарь операций (in-memory).
    public func loadInventory() -> [InventoryOperation] {
        inventory
    }

    /// Сохраняет переданный инвентарь операций (in-memory).
    /// - Parameter inventory: Новый массив операций для сохранения.
    public func saveInventory(_ inventory: [InventoryOperation]) {
        self.inventory = inventory
    }

    /// Добавляет новую операцию в инвентарь (in-memory).
    /// - Parameter operation: Операция для добавления.
    public func addOperation(_ operation: InventoryOperation) {
        inventory.append(operation)
    }

    /// Обновляет операцию по индексу (in-memory).
    /// - Parameters:
    ///   - index: Индекс операции для обновления.
    ///   - operation: Новая операция для замены.
    public func updateOperation(at index: Int, with operation: InventoryOperation) {
        guard inventory.indices.contains(index) else { return }
        inventory[index] = operation
    }

    /// Удаляет операцию по индексу (in-memory).
    /// - Parameter index: Индекс операции для удаления.
    public func removeOperation(at index: Int) {
        guard inventory.indices.contains(index) else { return }
        inventory.remove(at: index)
    }

    /// Очищает весь инвентарь (in-memory).
    public func clearInventory() {
        inventory = []
    }

    /// Деинициализатор. Очистка ресурсов не требуется для in-memory stub.
    deinit {
        // Очистка ресурсов не требуется
    }
}
