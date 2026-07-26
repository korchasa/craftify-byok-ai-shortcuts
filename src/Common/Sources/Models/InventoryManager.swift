import Foundation

/// Менеджер для управления инвентарём операций Craftify.
public final class InventoryManager: InventoryManaging {
    /// Текущий инвентарь операций
    public private(set) var inventory: [InventoryOperation] = []
    private let userDefaults: UserDefaults
    private let key = "CraftifyInventory"
    /// Приложение и расширение читают одно хранилище в App Group. Если оба
    /// раздадут идентификаторы старым записям и оба их запишут, порядок плиток
    /// разъедется, поэтому переписывает хранилище только приложение.
    private let migratesIdentifiers: Bool

    /// Инициализация менеджера с UserDefaults
    /// - Parameters:
    ///   - userDefaults: UserDefaults (обычно App Group)
    ///   - migratesIdentifiers: Разрешено ли дописывать идентификаторы старым записям
    public init(userDefaults: UserDefaults, migratesIdentifiers: Bool = false) {
        self.userDefaults = userDefaults
        self.migratesIdentifiers = migratesIdentifiers
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
        let context = InventoryOperationDecodingContext()
        let decoder = JSONDecoder()
        decoder.userInfo[InventoryOperationDecodingContext.userInfoKey] = context
        guard let decoded = try? decoder.decode([InventoryOperation].self, from: data) else {
            inventory = []
            return inventory
        }
        // Записям, сохранённым до появления сетки, ячейки раздаются по текущему
        // порядку — у существующих пользователей раскладка не разъезжается
        let normalized = OperationGrid.normalized(decoded)
        inventory = normalized
        // Старые записи получают идентификаторы и ячейки ровно один раз
        if context.didGenerateIdentifier, migratesIdentifiers {
            saveInventory(normalized)
        }
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
        if !inventory.isEmpty {
            return
        }
        let palette = ColorPaletteConstants.palette
        var colorIdx = 0
        func nextColor() -> String {
            defer { colorIdx = (colorIdx + 1) % palette.count }
            return palette[colorIdx]
        }
        var defaults: [InventoryOperation] = []
        // Helper to avoid duplicate translate operations for the same language
        var addedTranslateLanguages = Set<String>()
        func appendTranslate(to langCode: String) {
            guard !addedTranslateLanguages.contains(langCode) else { return }
            addedTranslateLanguages.insert(langCode)
            if let op = OperationFactory
                .make(kind: .translate)
                .makeInventoryOperation(input: OperationInput(targetLanguage: langCode), colorHex: nextColor())
            {
                defaults.append(op)
            }
        }

        // Determine device language
        let deviceLang = Locale.current.language.languageCode?.identifier ?? "en"

        // Order by expected frequency:
        // 1. translate → device language (or English if device is English)
        appendTranslate(to: deviceLang)

        // 2. translate → English (only if device language is not English)
        if deviceLang != "en" {
            appendTranslate(to: "en")
        }

        // 3. simplify
        if let op = OperationFactory
            .make(kind: .simplify)
            .makeInventoryOperation(input: OperationInput(), colorHex: nextColor())
        {
            defaults.append(op)
        }

        // 4. correct (fix)
        if let op = OperationFactory
            .make(kind: .correct)
            .makeInventoryOperation(input: OperationInput(), colorHex: nextColor())
        {
            defaults.append(op)
        }

        // 5. summarize (9–10 sentences)
        if let op = OperationFactory
            .make(kind: .summarize)
            .makeInventoryOperation(input: OperationInput(length: "9-10 sentences"), colorHex: nextColor())
        {
            defaults.append(op)
        }

        // 6. explain
        if let op = OperationFactory
            .make(kind: .explain)
            .makeInventoryOperation(input: OperationInput(), colorHex: nextColor())
        {
            defaults.append(op)
        }

        // 7. translate → Sindarin (sjn) – fun/example
        appendTranslate(to: "sjn")
        // Дефолтные плитки встают подряд с первой ячейки
        saveInventory(defaults.enumerated().map { index, operation in operation.with(slot: index) })
    }

    /// Деструктор. Освобождает ресурсы, если это необходимо.
    deinit {
        // Здесь можно освободить ресурсы, если потребуется.
    }
}
