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
    /// Ширина прогресс-бара
    public static let progressWidth: CGFloat = 180
    /// Радиус blur при обработке
    public static let blurRadius: CGFloat = 2
    /// Радиус скругления copiedToast
    public static let copiedToastCornerRadius: CGFloat = 12
    /// Прозрачность фона copiedToast
    public static let copiedToastBackgroundOpacity: Double = 0.95
    /// Радиус тени copiedToast
    public static let copiedToastShadowRadius: CGFloat = 4
    /// Отступ снизу copiedToast
    public static let copiedToastBottomSpacing: CGFloat = 40
    /// Вертикальный отступ внутри copiedToast
    public static let copiedToastVerticalSpacing: CGFloat = 8
    /// Горизонтальный отступ внутри copiedToast
    public static let copiedToastHorizontalSpacing: CGFloat = 16
    /// Шрифт copiedToast
    public static let copiedToastFont: Font = .headline
    /// Задержка скрытия copiedToast (секунды)
    public static let copiedToastHideDelay: TimeInterval = 2
}

extension Notification.Name {
    static let closeShareExtension = Notification.Name("closeShareExtension")
}
