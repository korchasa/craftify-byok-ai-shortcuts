import SwiftUI

/// Общие константы для стиля кнопок Craftify
public enum CraftifyButtonConstants {
    /// Red component for primary button color (0-1)
    public static let primaryRed: Double = 0.533
    /// Green component for primary button color (0-1)
    public static let primaryGreen: Double = 0.886
    /// Blue component for primary button color (0-1)
    public static let primaryBlue: Double = 0.776
    /// Red component for secondary button color (0-1)
    public static let secondaryRed: Double = 1.0
    /// Green component for secondary button color (0-1)
    public static let secondaryGreen: Double = 0.510
    /// Blue component for secondary button color (0-1)
    public static let secondaryBlue: Double = 0.490
    /// Основной цвет кнопки
    public static let primaryColor = Color(red: primaryRed, green: primaryGreen, blue: primaryBlue)
    /// Вторичный цвет кнопки (Cancel)
    public static let secondaryColor = Color(red: secondaryRed, green: secondaryGreen, blue: secondaryBlue)
    /// Радиус скругления кнопки
    public static let cornerRadius: CGFloat = 20
    /// Масштаб кнопки при нажатии
    public static let pressedScale: CGFloat = 0.97
    /// Прозрачность для вторичной кнопки
    public static let secondaryOpacity: Double = 0.5
    /// Horizontal padding for buttons
    public static let horizontalPadding: CGFloat = 16
    /// Bottom padding for buttons
    public static let bottomPadding: CGFloat = 16
    /// Minimum spacer height for button layouts
    public static let spacerMinLength: CGFloat = 0
    /// Минимальная высота кнопки
    public static let minButtonHeight: CGFloat = 44
    /// Масштаб кнопки по умолчанию
    public static let defaultScale: CGFloat = 1.0
}
