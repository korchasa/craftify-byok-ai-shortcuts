import UIKit

/// Утилита для вычисления высоты окна шаринга по количеству операций
public enum ShareExtensionViewHeight {
    private enum Constants {
        static let rowHeightMultiplier: CGFloat = 1.5
        static let headerFontHeight: CGFloat = 32
        static let minHeight: CGFloat = 220
        static let maxHeightMultiplier: CGFloat = 0.7
        static let columns: Int = 2
    }

    /// Вычисляет высоту окна шаринга по количеству операций
    /// - Parameter count: Количество операций
    /// - Returns: Рекомендуемая высота окна
    public static func calculate(count: Int) -> CGFloat {
        let rowHeight = ColorPaletteConstants.circleSize * Constants.rowHeightMultiplier
        let headerHeight = ShareExtensionViewConstants.topPadding + Constants.headerFontHeight
        let bottomPadding = ShareExtensionViewConstants.bottomPadding
        let minHeight = Constants.minHeight
        let maxHeight = UIScreen.main.bounds.height * Constants.maxHeightMultiplier
        let rows = CGFloat((count + Constants.columns - 1) / Constants.columns)
        let height = headerHeight + rows * rowHeight + bottomPadding
        return min(max(height, minHeight), maxHeight)
    }
}
