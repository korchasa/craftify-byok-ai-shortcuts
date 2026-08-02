import XCTest

/// Тесты раскладки операций по ячейкам сетки
public final class OperationGridTests: XCTestCase {
    private func makeOperation(_ kind: OperationKind, slot: Int) -> InventoryOperation {
        InventoryOperation(operation: kind, params: Data(), colorHex: "3288bd", slot: slot)
    }

    /// Между занятыми ячейками остаются дырки: плитка стоит там, куда её поставили
    public func testCellsKeepGapsBetweenOccupiedSlots() {
        let first = makeOperation(.translate, slot: 0)
        let second = makeOperation(.simplify, slot: 3)

        let cells = OperationGrid.cells(for: [first, second], minimumCells: 4)

        XCTAssertEqual(cells.count, 4)
        XCTAssertEqual(cells[0]?.id, first.id)
        XCTAssertNil(cells[1])
        XCTAssertNil(cells[2])
        XCTAssertEqual(cells[3]?.id, second.id)
    }

    /// Сетка всегда достаёт до самой дальней занятой ячейки, даже если запросили меньше
    public func testCellsGrowToFitTheFarthestOperation() {
        let far = makeOperation(.explain, slot: 6)

        let cells = OperationGrid.cells(for: [far], minimumCells: 2)

        XCTAssertEqual(cells.count, 7)
        XCTAssertEqual(cells[6]?.id, far.id)
    }

    /// Две операции на одной ячейке не съедают друг друга: вторая встаёт в ближайшую свободную
    public func testCollidingSlotsFallBackToTheNearestFreeCell() {
        let first = makeOperation(.translate, slot: 1)
        let second = makeOperation(.correct, slot: 1)

        let cells = OperationGrid.cells(for: [first, second], minimumCells: 4)

        XCTAssertEqual(cells[1]?.id, first.id)
        XCTAssertEqual(cells.compactMap { $0?.id }.count, 2)
        XCTAssertTrue(cells.contains { $0?.id == second.id })
    }

    /// Перенос на пустую ячейку просто меняет место операции
    public func testPlaceMovesOperationToEmptyCell() {
        let moved = makeOperation(.translate, slot: 0)
        let other = makeOperation(.simplify, slot: 1)

        let placed = OperationGrid.place([moved, other], id: moved.id, at: 5)

        XCTAssertEqual(placed.first { $0.id == moved.id }?.slot, 5)
        XCTAssertEqual(placed.first { $0.id == other.id }?.slot, 1)
    }

    /// Перенос на занятую ячейку меняет плитки местами
    public func testPlaceSwapsWithTheOperationAlreadyThere() {
        let moved = makeOperation(.translate, slot: 0)
        let other = makeOperation(.simplify, slot: 3)

        let placed = OperationGrid.place([moved, other], id: moved.id, at: 3)

        XCTAssertEqual(placed.first { $0.id == moved.id }?.slot, 3)
        XCTAssertEqual(placed.first { $0.id == other.id }?.slot, 0)
    }

    /// Перенос на собственную ячейку ничего не меняет
    public func testPlaceOnOwnCellIsANoOp() {
        let operation = makeOperation(.translate, slot: 2)

        XCTAssertEqual(OperationGrid.place([operation], id: operation.id, at: 2).first?.slot, 2)
    }

    /// Неизвестный идентификатор оставляет раскладку нетронутой
    public func testPlaceIgnoresUnknownOperation() {
        let operation = makeOperation(.translate, slot: 2)

        XCTAssertEqual(OperationGrid.place([operation], id: UUID(), at: 5).first?.slot, 2)
    }

    /// Записи без ячейки получают её по порядку и не наступают на занятые
    public func testNormalizedGivesEveryOperationAConcreteSlot() {
        let pinned = makeOperation(.translate, slot: 1)
        let legacyFirst = InventoryOperation(operation: .simplify, params: Data(), slot: InventoryOperation.unassignedSlot)
        let legacySecond = InventoryOperation(operation: .correct, params: Data(), slot: InventoryOperation.unassignedSlot)

        let normalized = OperationGrid.normalized([pinned, legacyFirst, legacySecond])

        XCTAssertEqual(normalized.first { $0.id == pinned.id }?.slot, 1)
        XCTAssertEqual(normalized.first { $0.id == legacyFirst.id }?.slot, 0)
        XCTAssertEqual(normalized.first { $0.id == legacySecond.id }?.slot, 2)
    }

    /// Раскладка с готовыми ячейками не меняется
    public func testNormalizedLeavesAssignedSlotsAlone() {
        let operations = [makeOperation(.translate, slot: 4), makeOperation(.simplify, slot: 0)]

        XCTAssertEqual(OperationGrid.normalized(operations).map(\.slot), [4, 0])
    }

    /// Ячейки нумеруются снизу вверх: нулевая — левая нижняя, новые прирастают сверху
    public func testDisplayOrderPutsTheFirstSlotAtTheBottomLeft() {
        let cells: [InventoryOperation?] = [
            makeOperation(.translate, slot: 0),
            makeOperation(.simplify, slot: 1),
            makeOperation(.correct, slot: 2),
            nil
        ]

        let rows = OperationGrid.displayOrder(cells, columns: 2)

        XCTAssertEqual(rows.map(\.slot), [2, 3, 0, 1])
        XCTAssertEqual(rows[0].operation?.operation, .correct)
        XCTAssertNil(rows[1].operation)
        XCTAssertEqual(rows[2].operation?.operation, .translate)
        XCTAssertEqual(rows[3].operation?.operation, .simplify)
    }

    /// Незаполненный верхний ряд остаётся сверху и не съезжает вниз
    public func testDisplayOrderKeepsAPartialRowOnTop() {
        let cells: [InventoryOperation?] = [
            makeOperation(.translate, slot: 0),
            makeOperation(.simplify, slot: 1),
            makeOperation(.correct, slot: 2)
        ]

        XCTAssertEqual(OperationGrid.displayOrder(cells, columns: 2).map(\.slot), [2, 3, 0, 1])
    }

    /// Пустые ряды уходят, дырки внутри ряда остаются: расширение показывает
    /// только подходящие входу операции и не должно зиять пустыми рядами
    public func testWithoutEmptyRowsDropsRowsWithNoOperations() {
        let first = makeOperation(.translate, slot: 1)
        let second = makeOperation(.simplify, slot: 4)
        let cells = OperationGrid.cells(for: [first, second], minimumCells: 0)

        let trimmed = OperationGrid.withoutEmptyRows(cells, columns: 2)

        XCTAssertEqual(trimmed.count, 4)
        XCTAssertNil(trimmed[0])
        XCTAssertEqual(trimmed[1]?.id, first.id)
        XCTAssertEqual(trimmed[2]?.id, second.id)
        XCTAssertNil(trimmed[3])
    }

    /// Первая свободная ячейка — для кнопки «Добавить» внизу экрана
    public func testFirstFreeSlotSkipsOccupiedCells() {
        let first = makeOperation(.translate, slot: 0)
        let second = makeOperation(.simplify, slot: 2)

        XCTAssertEqual(OperationGrid.firstFreeSlot(in: [first, second]), 1)
        XCTAssertEqual(OperationGrid.firstFreeSlot(in: []), 0)
    }
}
