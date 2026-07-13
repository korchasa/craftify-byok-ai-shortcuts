import SwiftUI

/// Константы для UI ShareExtensionView (отступы, размеры, стили)
public enum ShareExtensionViewConstants {
    /// Вертикальный отступ между элементами
    public static let verticalSpacing: CGFloat = 16
    /// Отступ сверху для заголовка
    public static let topPadding: CGFloat = 24
    /// Отступ снизу для кнопки
    public static let bottomPadding: CGFloat = 24
    /// Отступ между колонками операций
    public static let gridSpacing: CGFloat = 16
    /// Радиус скругления overlay прогресса
    public static let overlayCornerRadius: CGFloat = 16
    /// Прозрачность overlay прогресса
    public static let overlayOpacity: Double = 0.95
    /// Тень overlay прогресса
    public static let overlayShadow: CGFloat = 8
    /// Ширина popover на iPad
    public static let popoverWidth: CGFloat = 380
    /// Радиус blur при обработке
    public static let blurRadius: CGFloat = 2
    /// Отступ над заголовком контента
    public static let contentTopSpacing: CGFloat = 8
    /// Множитель высоты для кнопки операции
    public static let operationHeightMultiplier: CGFloat = 1.5
    /// Минимальная высота кнопки операции
    public static let operationMinHeight: CGFloat = operationHeightMultiplier * ColorPickerLayoutConstants.circleSize
}

/// Расширение для уведомлений ShareExtension
/// Позволяет отправлять уведомление о закрытии расширения.
public extension Notification.Name {
    /// Уведомление для закрытия ShareExtension
    static let closeShareExtension = Notification.Name("closeShareExtension")
}
