import SwiftUI

/// Абстракция палитры цветов Craftify.
public protocol ColorPaletteProviding {
    /// Цвет фона.
    func backgroundColor() -> Color
    /// Основной цвет текста.
    func textColor() -> Color
    /// Вторичный цвет текста.
    func secondaryTextColor() -> Color
    /// Цвет для destructive-действий.
    func destructiveColor() -> Color
    /// Цвет для ссылок.
    func linkColor() -> Color
    /// Вторичный цвет для UI.
    func secondaryColor() -> Color
    /// Палитра hex-цветов для операций.
    func palette() -> [String]
    /// Размер круга для выбора цвета.
    var circleSize: CGFloat { get }
    /// Отступ между кругами.
    var circleSpacing: CGFloat { get }
    /// Толщина рамки вокруг выбранного цвета.
    var borderWidth: CGFloat { get }
    /// Вертикальный отступ между элементами палитры.
    var verticalSpacing: CGFloat { get }
    /// Нижний отступ палитры.
    var bottomPadding: CGFloat { get }
}
