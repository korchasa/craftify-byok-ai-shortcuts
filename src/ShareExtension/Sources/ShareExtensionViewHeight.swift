import UIKit

/// Размер окна шаринга на iPad, где расширение показывается в popover
public enum ShareExtensionViewHeight {
    private enum Constants {
        static let maxHeightMultiplier: CGFloat = 0.7
    }

    /// Максимальная высота окна для данного экрана (используется и как высота popover с результатом)
    public static func maxHeight(screenHeight: CGFloat) -> CGFloat {
        screenHeight * Constants.maxHeightMultiplier
    }
}
