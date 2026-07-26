import SwiftUI

// [REF:fr:ux.tile-arrange]
/// Приём перетаскиваемой плитки на конкретную ячейку сетки. Плитку можно
/// положить куда угодно: на пустое место она просто переезжает, на занятое —
/// меняется местами с соседом. Порядок соседей при этом не сдвигается.
public struct OperationDropDelegate: DropDelegate {
    private let slot: Int
    @Binding private var draggingID: UUID?
    @Binding private var highlightedSlot: Int?
    private let onPlace: (UUID, Int) -> Void

    /// Создаёт приёмник для одной ячейки сетки
    /// - Parameters:
    ///   - slot: Номер ячейки
    ///   - draggingID: Идентификатор перетаскиваемой операции
    ///   - highlightedSlot: Ячейка под пальцем — её подсвечивает сетка
    ///   - onPlace: Поставить операцию в эту ячейку
    public init(
        slot: Int,
        draggingID: Binding<UUID?>,
        highlightedSlot: Binding<Int?>,
        onPlace: @escaping (UUID, Int) -> Void
    ) {
        self.slot = slot
        self._draggingID = draggingID
        self._highlightedSlot = highlightedSlot
        self.onPlace = onPlace
    }

    public func dropEntered(info _: DropInfo) {
        highlightedSlot = slot
    }

    public func dropExited(info _: DropInfo) {
        if highlightedSlot == slot {
            highlightedSlot = nil
        }
    }

    public func dropUpdated(info _: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    public func performDrop(info _: DropInfo) -> Bool {
        highlightedSlot = nil
        guard let id = draggingID else { return false }
        draggingID = nil
        onPlace(id, slot)
        return true
    }
}
