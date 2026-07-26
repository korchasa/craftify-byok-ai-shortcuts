import SwiftUI

// [REF:fr:ux.tile-arrange]
/// Приём перетаскиваемой плитки на конкретную ячейку сетки. Плитку можно
/// положить куда угодно: на пустое место она просто переезжает, на занятое —
/// меняется местами с соседом. Порядок соседей при этом не сдвигается.
public struct OperationDropDelegate: DropDelegate {
    private let slot: Int
    @Binding private var dragSourceID: UUID?
    @Binding private var draggingID: UUID?
    @Binding private var highlightedSlot: Int?
    private let onPlace: (UUID, Int) -> Void

    /// Создаёт приёмник для одной ячейки сетки
    /// - Parameters:
    ///   - slot: Номер ячейки
    ///   - dragSourceID: Идентификатор поднятой операции
    ///   - draggingID: Идентификатор операции, которая едет над сеткой
    ///   - highlightedSlot: Ячейка под пальцем — её подсвечивает сетка
    ///   - onPlace: Поставить операцию в эту ячейку
    public init(
        slot: Int,
        dragSourceID: Binding<UUID?>,
        draggingID: Binding<UUID?>,
        highlightedSlot: Binding<Int?>,
        onPlace: @escaping (UUID, Int) -> Void
    ) {
        self.slot = slot
        self._dragSourceID = dragSourceID
        self._draggingID = draggingID
        self._highlightedSlot = highlightedSlot
        self.onPlace = onPlace
    }

    /// Перенос дошёл до ячейки — значит плитку действительно тащат, и её место
    /// в сетке пора показать пустым
    public func dropEntered(info _: DropInfo) {
        highlightedSlot = slot
        draggingID = dragSourceID
    }

    /// Палец ушёл с ячейки. Сбрасываем состояние только если следом не пришли в
    /// соседнюю: заход в новую ячейку приходит раньше выхода из старой.
    /// Так же гасится и отменённый перенос — например когда плитку удержали
    /// ради режима правки и отпустили, не сдвинув
    public func dropExited(info _: DropInfo) {
        if highlightedSlot == slot {
            highlightedSlot = nil
            draggingID = nil
        }
    }

    public func dropUpdated(info _: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    public func performDrop(info _: DropInfo) -> Bool {
        highlightedSlot = nil
        // Берём именно едущую плитку: поднятая помнится и после отменённого
        // переноса, и по ней ячейка переставляла бы плитку от прошлого жеста
        guard let id = draggingID else { return false }
        draggingID = nil
        dragSourceID = nil
        onPlace(id, slot)
        return true
    }
}
