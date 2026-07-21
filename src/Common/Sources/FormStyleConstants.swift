import Foundation
import SwiftUI

/// Общие константы для стиля форм Craftify
public enum FormStyleConstants {
    /// Левый отступ для формы
    public static let formLeadingPadding: CGFloat = 16
    /// Правый отступ для формы
    public static let formTrailingPadding: CGFloat = 16
    /// Нижний отступ для кнопок/формы
    public static let bottomPadding: CGFloat = 16
    /// Верхний отступ перед заголовком окна
    public static let formTopPadding: CGFloat = 32
    /// Верхний отступ перед формой
    public static let formContentTopPadding: CGFloat = 16
    /// Отступ под линией-разделителем между заголовком и контентом
    public static let dividerBottomPadding: CGFloat = 8
    /// Вертикальный отступ между секциями формы
    public static let sectionSpacing: CGFloat = 16
    /// Отступ сверху для секции родного языка в настройках
    public static let nativeLanguageSectionTopPadding: CGFloat = 2
    /// Минимальная ширина popover выбора модели (iPad)
    public static let modelPickerPopoverMinWidth: CGFloat = 420
    /// Минимальная высота popover выбора модели (iPad)
    public static let modelPickerPopoverMinHeight: CGFloat = 560
}
