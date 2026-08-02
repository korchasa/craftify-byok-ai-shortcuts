import Foundation

// [REF:fr:ux.tile-arrange]
/// Раскладка операций по ячейкам сетки. Чистые функции без UI и хранилища:
/// экран — это набор мест, каждая операция занимает своё, а между занятыми
/// ячейками могут оставаться пустые.
public enum OperationGrid {
    /// Раскладывает операции по ячейкам. Длина результата — не меньше
    /// `minimumCells` и всегда достаёт до самой дальней занятой ячейки.
    /// Операции без назначенной ячейки и те, что столкнулись с уже занятой,
    /// встают в ближайшую свободную — раскладка не теряет ни одной плитки.
    /// - Parameters:
    ///   - operations: Операции инвентаря
    ///   - minimumCells: Сколько ячеек показать как минимум
    /// - Returns: Массив ячеек; nil — ячейка пуста
    public static func cells(for operations: [InventoryOperation], minimumCells: Int) -> [InventoryOperation?] {
        var placed: [Int: InventoryOperation] = [:]
        var homeless: [InventoryOperation] = []
        for operation in operations {
            let slot = operation.slot
            if slot >= 0, placed[slot] == nil {
                placed[slot] = operation
            } else {
                homeless.append(operation)
            }
        }
        for operation in homeless {
            placed[firstFreeSlot(occupied: Set(placed.keys))] = operation
        }
        let required = (placed.keys.max().map { $0 + 1 } ?? 0)
        let count = max(minimumCells, required)
        return (0 ..< count).map { placed[$0] }
    }

    /// Переносит операцию в указанную ячейку. Если ячейка занята, плитки
    /// меняются местами — так перетаскивание никогда не теряет соседа.
    /// - Parameters:
    ///   - operations: Операции инвентаря
    ///   - id: Идентификатор переносимой операции
    ///   - slot: Ячейка назначения
    /// - Returns: Новый список операций с обновлёнными ячейками
    public static func place(_ operations: [InventoryOperation], id: UUID, at slot: Int) -> [InventoryOperation] {
        guard slot >= 0, let moved = operations.first(where: { $0.id == id }), moved.slot != slot else {
            return operations
        }
        let displaced = operations.first { $0.slot == slot && $0.id != id }
        return operations.map { operation in
            if operation.id == moved.id {
                return operation.with(slot: slot)
            }
            if operation.id == displaced?.id {
                return operation.with(slot: moved.slot)
            }
            return operation
        }
    }

    /// Выдаёт ячейку каждой операции, у которой её ещё нет: записи, сохранённые
    /// до появления сетки, встают по порядку в свободные места.
    /// - Parameter operations: Операции инвентаря
    /// - Returns: Тот же список, но с конкретной ячейкой у каждой операции
    public static func normalized(_ operations: [InventoryOperation]) -> [InventoryOperation] {
        var occupied = Set(operations.map(\.slot).filter { $0 >= 0 })
        return operations.map { operation in
            guard operation.slot < 0 else { return operation }
            let slot = firstFreeSlot(occupied: occupied)
            occupied.insert(slot)
            return operation.with(slot: slot)
        }
    }

    /// Порядок вывода ячеек на экране. Нумерация идёт снизу вверх: нулевая
    /// ячейка — левая нижняя, следующая — правая нижняя, дальше ряд выше.
    /// Так самые нужные плитки остаются под большим пальцем, а новые ячейки
    /// прирастают сверху. Неполный верхний ряд добивается до целого.
    /// - Parameters:
    ///   - cells: Ячейки в порядке номеров
    ///   - columns: Число колонок сетки
    /// - Returns: Пары «номер ячейки, операция» в порядке отрисовки сверху вниз
    public static func displayOrder(
        _ cells: [InventoryOperation?],
        columns: Int
    ) -> [(slot: Int, operation: InventoryOperation?)] {
        guard columns > 0 else { return [] }
        let rowCount = Int((Double(cells.count) / Double(columns)).rounded(.up))
        return (0 ..< rowCount).reversed().flatMap { row in
            (0 ..< columns).map { column in
                let slot = row * columns + column
                return (slot: slot, operation: slot < cells.count ? cells[slot] : nil)
            }
        }
    }

    /// Выбрасывает ряды, где нет ни одной операции. Дырки внутри ряда остаются:
    /// они держат плитки на своих местах. Нужно расширению — там показывают
    /// только операции, подходящие входу, и пустые ряды раздували бы карточку.
    /// - Parameters:
    ///   - cells: Ячейки в порядке номеров
    ///   - columns: Число колонок сетки
    /// - Returns: Те же ячейки без целиком пустых рядов
    public static func withoutEmptyRows(_ cells: [InventoryOperation?], columns: Int) -> [InventoryOperation?] {
        guard columns > 0 else { return [] }
        let rowCount = Int((Double(cells.count) / Double(columns)).rounded(.up))
        return (0 ..< rowCount).flatMap { row -> [InventoryOperation?] in
            let rowCells = (0 ..< columns).map { column -> InventoryOperation? in
                let slot = row * columns + column
                return slot < cells.count ? cells[slot] : nil
            }
            return rowCells.contains(where: { $0 != nil }) ? rowCells : []
        }
    }

    /// Первая свободная ячейка — туда кладёт операцию кнопка «Добавить» внизу экрана
    /// - Parameter operations: Операции инвентаря
    /// - Returns: Номер свободной ячейки
    public static func firstFreeSlot(in operations: [InventoryOperation]) -> Int {
        firstFreeSlot(occupied: Set(operations.map(\.slot)))
    }

    private static func firstFreeSlot(occupied: Set<Int>) -> Int {
        var candidate = 0
        while occupied.contains(candidate) {
            candidate += 1
        }
        return candidate
    }
}
