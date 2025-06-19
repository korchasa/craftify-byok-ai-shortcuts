import Foundation

/// Менеджер для управления инвентарём операций Craftify.
public final class InventoryManager: InventoryManaging {
    /// Текущий инвентарь операций
    public private(set) var inventory: [InventoryOperation] = []
    private let userDefaults: UserDefaults
    private let key = "CraftifyInventory"

    /// Инициализация менеджера с UserDefaults
    /// - Parameter userDefaults: UserDefaults (обычно App Group)
    public init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
        loadInventory()
    }

    /// Загружает инвентарь операций из UserDefaults.
    /// - Returns: Массив операций инвентаря.
    @discardableResult
    public func loadInventory() -> [InventoryOperation] {
        guard let data = userDefaults.data(forKey: key) else {
            inventory = []
            return inventory
        }
        guard let decoded = try? JSONDecoder().decode([InventoryOperation].self, from: data) else {
            inventory = []
            return inventory
        }
        inventory = decoded
        return inventory
    }

    /// Сохраняет инвентарь операций в UserDefaults.
    /// - Parameter inventory: Массив операций для сохранения.
    public func saveInventory(_ inventory: [InventoryOperation]) {
        self.inventory = inventory
        if let data = try? JSONEncoder().encode(inventory) {
            userDefaults.set(data, forKey: key)
        }
    }

    /// Добавляет новую операцию в инвентарь.
    /// - Parameter operation: Операция для добавления.
    public func addOperation(_ operation: InventoryOperation) {
        inventory.append(operation)
        saveInventory(inventory)
    }

    /// Обновляет существующую операцию в инвентаре по индексу.
    /// - Parameters:
    ///   - index: Индекс операции для обновления.
    ///   - operation: Новая операция для замены.
    public func updateOperation(at index: Int, with operation: InventoryOperation) {
        guard inventory.indices.contains(index) else { return }
        inventory[index] = operation
        saveInventory(inventory)
    }

    /// Удаляет операцию из инвентаря по индексу.
    /// - Parameter index: Индекс операции для удаления.
    public func removeOperation(at index: Int) {
        guard inventory.indices.contains(index) else { return }
        inventory.remove(at: index)
        saveInventory(inventory)
    }

    /// Очищает весь инвентарь операций.
    public func clearInventory() {
        inventory = []
        saveInventory(inventory)
    }

    /// Заполняет инвентарь дефолтными операциями, если он пуст
    public func fillWithDefaultOperationsIfNeeded() {
        if !inventory.isEmpty { return }
        let palette = ColorPaletteConstants.palette
        var colorIdx = 0
        func nextColor() -> String {
            defer { colorIdx = (colorIdx + 1) % palette.count }
            return palette[colorIdx]
        }
        var defaults: [InventoryOperation] = []
        // correct
        if let op = OperationFactory.make(kind: .correct).makeInventoryOperation(input: OperationInput(), colorHex: nextColor()) {
            defaults.append(op)
        }
        // simplify teenager
        if let op = OperationFactory.make(kind: .simplify).makeInventoryOperation(input: OperationInput(complexityLevel: .teenager), colorHex: nextColor()) {
            defaults.append(op)
        }
        // explain teenager
        if let op = OperationFactory.make(kind: .explain).makeInventoryOperation(input: OperationInput(detailLevel: .teenager), colorHex: nextColor()) {
            defaults.append(op)
        }
        // translate english
        if let op = OperationFactory.make(kind: .translate).makeInventoryOperation(input: OperationInput(targetLanguage: "en"), colorHex: nextColor()) {
            defaults.append(op)
        }
        // translate dothraki
        if let op = OperationFactory.make(kind: .translate).makeInventoryOperation(input: OperationInput(targetLanguage: "dtr"), colorHex: nextColor()) {
            defaults.append(op)
        }
        // summarize
        if let op = OperationFactory.make(kind: .summarize).makeInventoryOperation(input: OperationInput(), colorHex: nextColor()) {
            defaults.append(op)
        }
        saveInventory(defaults)
    }

    /// Деструктор. Освобождает ресурсы, если это необходимо.
    deinit {
        // Здесь можно освободить ресурсы, если потребуется.
    }
}
