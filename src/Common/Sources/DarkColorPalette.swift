// Реализация находится в ColorPaletteProviding.swift

import SwiftUI

/// Реализация тёмной палитры Craftify.
public struct DarkColorPalette: ColorPaletteProviding {
    // MARK: - Color Constants

    private static let backgroundRed: Double = 0.09
    private static let backgroundGreen: Double = 0.09
    private static let backgroundBlue: Double = 0.11
    private static let textRed: Double = 1.0
    private static let textGreen: Double = 1.0
    private static let textBlue: Double = 1.0
    private static let secondaryTextRed: Double = 0.7
    private static let secondaryTextGreen: Double = 0.7
    private static let secondaryTextBlue: Double = 0.75
    private static let destructiveRed: Double = 1.0
    private static let destructiveGreen: Double = 0.3
    private static let destructiveBlue: Double = 0.3
    private static let linkRed: Double = 0.4
    private static let linkGreen: Double = 0.7
    private static let linkBlue: Double = 1.0
    private static let whiteRed: Double = 0.13
    private static let whiteGreen: Double = 0.13
    private static let whiteBlue: Double = 0.15
    private static let paletteHex: [String] = [
        "ef476f", "f78c6b", "ffd166", "83d483", "06d6a0",
        "0cb0a9", "118ab2", "0c637f", "073b4c"
    ]

    // MARK: - UI Constants

    /// Размер круга для выбора цвета
    public let circleSize: CGFloat = 30
    /// Отступ между кругами
    public let circleSpacing: CGFloat = 12
    /// Толщина рамки вокруг выбранного цвета
    public let borderWidth: CGFloat = 3
    /// Вертикальный отступ между элементами палитры
    public let verticalSpacing: CGFloat = 8
    /// Нижний отступ палитры
    public let bottomPadding: CGFloat = 4
    /// Инициализация тёмной палитры
    public init() {}
    /// Цвет фона
    public func backgroundColor() -> Color {
        Color(red: Self.backgroundRed, green: Self.backgroundGreen, blue: Self.backgroundBlue)
    }

    /// Основной цвет текста
    public func textColor() -> Color {
        Color(red: Self.textRed, green: Self.textGreen, blue: Self.textBlue)
    }

    /// Вторичный цвет текста
    public func secondaryTextColor() -> Color {
        Color(red: Self.secondaryTextRed, green: Self.secondaryTextGreen, blue: Self.secondaryTextBlue)
    }

    /// Цвет для destructive-действий
    public func destructiveColor() -> Color {
        Color(red: Self.destructiveRed, green: Self.destructiveGreen, blue: Self.destructiveBlue)
    }

    /// Цвет для ссылок
    public func linkColor() -> Color {
        Color(red: Self.linkRed, green: Self.linkGreen, blue: Self.linkBlue)
    }

    /// Вторичный цвет
    public func secondaryColor() -> Color {
        Color(red: Self.secondaryTextRed, green: Self.secondaryTextGreen, blue: Self.secondaryTextBlue)
    }

    /// Палитра hex-цветов для операций
    public func palette() -> [String] {
        Self.paletteHex
    }
}
