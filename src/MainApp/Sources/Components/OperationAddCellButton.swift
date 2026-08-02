import SwiftUI

// [REF:fr:ux.tile-arrange]
/// Пустая ячейка сетки: пунктирная рамка с «+ Добавить».
/// Нажатие создаёт операцию именно в этой ячейке, а не в конце списка.
public struct OperationAddCellButton: View {
    private let slot: Int
    private let isHighlighted: Bool
    private let action: () -> Void
    @Environment(\.colorPalette) private var palette
    @ScaledMetric(relativeTo: .body) private var height: CGFloat = OperationTileConstants.height

    /// Создаёт кнопку добавления для пустой ячейки
    /// - Parameters:
    ///   - slot: Номер ячейки
    ///   - isHighlighted: Над ячейкой держат перетаскиваемую плитку
    ///   - action: Открыть форму добавления для этой ячейки
    public init(slot: Int, isHighlighted: Bool, action: @escaping () -> Void) {
        self.slot = slot
        self.isHighlighted = isHighlighted
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Label(L10n.homeAddOperation, systemImage: "plus")
                .font(.craftifyFootnote)
                .fontWeight(.semibold)
                .foregroundColor(palette.secondaryText())
                .frame(maxWidth: .infinity, minHeight: height)
                .background(background)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(L10n.homeAddOperation)
        .accessibilityIdentifier("operation_add_slot_\(slot)")
    }

    /// Пунктирная рамка отличает пустое место от плитки, а заливка появляется,
    /// когда над ячейкой держат перетаскиваемую плитку
    private var background: some View {
        RoundedRectangle(cornerRadius: OperationTileConstants.cornerRadius)
            .strokeBorder(
                palette.secondaryText().opacity(OperationTileConstants.emptyCellBorderOpacity),
                style: StrokeStyle(
                    lineWidth: OperationTileConstants.emptyCellBorderWidth,
                    dash: [OperationTileConstants.emptyCellDashLength]
                )
            )
            .background(
                RoundedRectangle(cornerRadius: OperationTileConstants.cornerRadius)
                    .fill(palette.secondaryText().opacity(
                        isHighlighted ? OperationTileConstants.dropHighlightOpacity : 0
                    ))
            )
    }
}
