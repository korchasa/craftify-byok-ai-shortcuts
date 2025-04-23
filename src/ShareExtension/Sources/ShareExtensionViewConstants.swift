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
}
