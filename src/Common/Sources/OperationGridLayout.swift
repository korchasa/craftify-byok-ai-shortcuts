import SwiftUI

/// Раскладка сетки плиток операций — общая для главного экрана и экрана выбора,
/// чтобы плитки на обоих стояли одинаково.
public enum OperationGridLayout {
    /// Колонки сетки плиток
    public static let columns: [GridItem] = Array(
        repeating: GridItem(.flexible(), spacing: OperationTileConstants.gridSpacing),
        count: OperationTileConstants.columns
    )

    /// Ширина одной ячейки. Нужна превью перетаскивания: у него нет родителя,
    /// который задал бы ширину, а плитка должна тащиться в своём размере.
    /// Ширину берём у контейнера сетки, а не у экрана: на iPad окно приложения
    /// бывает уже экрана, и превью тогда вылезало бы за плитку.
    /// - Parameters:
    ///   - containerWidth: Ширина контейнера, в котором лежит сетка
    ///   - horizontalPadding: Отступ сетки от краёв
    /// - Returns: Ширина ячейки
    public static func cellWidth(containerWidth: CGFloat, horizontalPadding: CGFloat) -> CGFloat {
        let gapCount = OperationTileConstants.columns - 1
        let gaps = OperationTileConstants.gridSpacing * CGFloat(gapCount)
        let available = containerWidth - horizontalPadding - horizontalPadding - gaps
        return max(0, available / CGFloat(OperationTileConstants.columns))
    }
}
