import UIKit

/// Утилита для вычисления высоты окна шаринга
public enum ShareExtensionViewHeight {
    private enum Constants {
        /// Ожидаемая высота шапки с обрабатываемым текстом: подпись плюс несколько строк
        static let inputPreviewHeight: CGFloat = 96
        static let minHeight: CGFloat = 220
        static let maxHeightMultiplier: CGFloat = 0.7
    }

    /// Вычисляет высоту окна шаринга по количеству операций (фолбэк до первого замера контента)
    /// - Parameters:
    ///   - count: Количество операций
    ///   - screenHeight: Высота экрана для верхней границы
    /// - Returns: Рекомендуемая высота окна
    public static func calculate(count: Int, screenHeight: CGFloat = UIScreen.main.bounds.height) -> CGFloat {
        let rowHeight = OperationTileConstants.height + OperationTileConstants.gridSpacing
        let headerHeight = ShareExtensionViewConstants.topPadding
            + Constants.inputPreviewHeight
            + ShareExtensionViewConstants.inputPreviewBottomSpacing
        let bottomPadding = ShareExtensionViewConstants.bottomPadding
        let rows = CGFloat((count + OperationTileConstants.columns - 1) / OperationTileConstants.columns)
        let height = headerHeight + rows * rowHeight + bottomPadding
        return clamp(height, screenHeight: screenHeight)
    }

    /// Вычисляет высоту кастомного detent по замеренному контенту.
    /// Возвращает nil, когда показан результат — шторка разворачивается на .large().
    /// - Parameters:
    ///   - measuredContentHeight: Замеренная высота контента (0 до первого layout-прохода)
    ///   - operationsCount: Количество операций для фолбэка
    ///   - hasResult: Показан ли результат обработки
    ///   - screenHeight: Высота экрана для верхней границы
    public static func detent(
        measuredContentHeight: CGFloat,
        operationsCount: Int,
        hasResult: Bool,
        screenHeight: CGFloat
    ) -> CGFloat? {
        if hasResult {
            return nil
        }
        guard measuredContentHeight > 0 else {
            return calculate(count: operationsCount, screenHeight: screenHeight)
        }
        return clamp(measuredContentHeight, screenHeight: screenHeight)
    }

    /// Максимальная высота окна для данного экрана (используется и как высота popover с результатом)
    public static func maxHeight(screenHeight: CGFloat) -> CGFloat {
        screenHeight * Constants.maxHeightMultiplier
    }

    private static func clamp(_ height: CGFloat, screenHeight: CGFloat) -> CGFloat {
        min(max(height, Constants.minHeight), maxHeight(screenHeight: screenHeight))
    }
}
