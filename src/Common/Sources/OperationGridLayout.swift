import SwiftUI

/// Раскладка сетки плиток операций — общая для главного экрана и экрана выбора,
/// чтобы плитки на обоих стояли одинаково.
public enum OperationGridLayout {
    /// Число колонок при данном размере шрифта. На размерах из «Универсального
    /// доступа» две плитки в ряд оставляют названию пару букв, поэтому сетка
    /// становится одной колонкой — так Apple советует поступать с горизонтальными
    /// рядами при крупном тексте
    /// - Parameter dynamicTypeSize: Текущий системный размер шрифта
    /// - Returns: Число колонок сетки
    public static func columnCount(for dynamicTypeSize: DynamicTypeSize) -> Int {
        // [REF:fr:ux.dynamic-type]
        dynamicTypeSize.isAccessibilitySize ? 1 : OperationTileConstants.columns
    }

    /// Колонки сетки плиток
    /// - Parameter count: Число колонок
    /// - Returns: Описание колонок для `LazyVGrid`
    public static func columns(count: Int) -> [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: OperationTileConstants.gridSpacing),
            count: count
        )
    }

    /// Ширина одной ячейки. Нужна превью перетаскивания: у него нет родителя,
    /// который задал бы ширину, а плитка должна тащиться в своём размере.
    /// Ширину берём у контейнера сетки, а не у экрана: на iPad окно приложения
    /// бывает уже экрана, и превью тогда вылезало бы за плитку.
    /// - Parameters:
    ///   - containerWidth: Ширина контейнера, в котором лежит сетка
    ///   - horizontalPadding: Отступ сетки от краёв
    ///   - columnCount: Число колонок сетки
    /// - Returns: Ширина ячейки
    public static func cellWidth(
        containerWidth: CGFloat,
        horizontalPadding: CGFloat,
        columnCount: Int = OperationTileConstants.columns
    ) -> CGFloat {
        guard columnCount > 0 else { return 0 }
        let gaps = OperationTileConstants.gridSpacing * CGFloat(columnCount - 1)
        let available = containerWidth - horizontalPadding - horizontalPadding - gaps
        return max(0, available / CGFloat(columnCount))
    }
}
