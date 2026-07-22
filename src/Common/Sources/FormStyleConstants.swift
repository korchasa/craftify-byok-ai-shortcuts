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
    /// Вертикальный внутренний отступ строки поиска в пикере моделей
    public static let searchBarVerticalPadding: CGFloat = 8
    /// Горизонтальный внутренний отступ строки поиска в пикере моделей
    public static let searchBarHorizontalPadding: CGFloat = 10
    /// Скругление фона строки поиска в пикере моделей
    public static let searchBarCornerRadius: CGFloat = 10
    /// Минимальная высота редактора промпта операции
    public static let promptEditorMinHeight: CGFloat = 140
    /// Максимальная высота редактора промпта операции
    public static let promptEditorMaxHeight: CGFloat = 220
    /// Внутренний отступ редактора промпта
    public static let promptEditorInnerPadding: CGFloat = 4
    /// Прозрачность рамки редактора промпта
    public static let promptEditorBorderOpacity: Double = 0.4
}
