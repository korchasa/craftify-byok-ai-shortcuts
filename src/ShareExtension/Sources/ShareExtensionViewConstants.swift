import SwiftUI

/// Константы для UI ShareExtensionView (отступы, размеры, стили)
public enum ShareExtensionViewConstants {
    /// Вертикальный отступ между элементами
    public static let verticalSpacing: CGFloat = 16
    /// Отступ сверху для заголовка
    public static let topPadding: CGFloat = 24
    /// Отступ снизу для кнопки
    public static let bottomPadding: CGFloat = 24
    /// Отступ между подписью «над чем работаем» и самим текстом
    public static let inputPreviewSpacing: CGFloat = 6
    /// Разрядка букв в подписи «над чем работаем»
    public static let inputPreviewCaptionKerning: CGFloat = 1.1
    /// Отступ под шапкой с входным текстом
    public static let inputPreviewBottomSpacing: CGFloat = 20
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
    /// Скругление верхних углов карточки с операциями
    public static let cardCornerRadius: CGFloat = 24
}

/// Расширение для уведомлений ShareExtension
/// Позволяет отправлять уведомление о закрытии расширения.
public extension Notification.Name {
    /// Уведомление для закрытия ShareExtension
    static let closeShareExtension = Notification.Name("closeShareExtension")
}
