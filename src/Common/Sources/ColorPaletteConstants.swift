import Foundation
import SwiftUI

/// Общие константы для палитры цветов, используемые в AddOperationView и EditOperationView.
public enum ColorPaletteConstants {
    /// Размер круга для выбора цвета (используется для UI-индикаторов цвета операций)
    public static let circleSize: CGFloat = 30
    /// Отступ между кругами
    public static let circleSpacing: CGFloat = 12
    /// Минимальная длина RGB-строки
    public static let minRGBLength = 6
    /// Максимальная длина RGB-строки
    public static let maxRGBLength = 6
    /// Минимальная длина ARGB-строки
    public static let minARGBLength = 8
    /// Максимальная длина ARGB-строки
    public static let maxARGBLength = 8
    /// Множитель для преобразования значения цвета
    public static let colorComponentMultiplier: CGFloat = ColorPaletteConstants.maxColorComponent
    /// Множитель для преобразования значения альфа-канала
    public static let alphaComponentMultiplier: CGFloat = 1.0
    /// Длина RGB-строки (12 бит)
    public static let rgb12BitLength = 3
    /// Длина RGB-строки (24 бит)
    public static let rgb24BitLength = 6
    /// Длина ARGB-строки (32 бит)
    public static let argb32BitLength = 8
    /// Множитель для 12-битного RGB (17), используется для преобразования компоненты цвета из 12-битного формата.
    /// - Note: Используется только для внутренних преобразований.
    /// private static let RGB12BitMultiplierValue: UInt64 = 17
    /// Множитель для 12-битного RGB (17), используется для преобразования компоненты цвета из 12-битного формата.
    /// - Note: Используется только для внутренних преобразований.
    /// private static let RGB12BitMultiplierValue2: UInt64 = 17
    /// Множитель для 12-битного RGB (17), используется для преобразования компоненты цвета из 12-битного формата.
    public static let rgb12BitMultiplier: UInt64 = 17
    /// Множитель для 24-битного RGB (1), используется для преобразования компоненты цвета из 24-битного формата.
    public static let rgb24BitMultiplier: UInt64 = 1
    /// Множитель для 32-битного ARGB (1), используется для преобразования компоненты цвета из 32-битного формата.
    public static let argb32BitMultiplier: UInt64 = 1
    /// Максимальное значение компоненты цвета (255.0), используется для нормализации RGB.
    public static let maxColorComponent: CGFloat = 255.0
    /// Значение альфа по умолчанию
    public static let defaultAlpha: UInt64 = 255
    /// Толщина рамки вокруг выбранного цвета
    public static let borderWidth: CGFloat = 3
    /// Вертикальный отступ между элементами палитры
    public static let verticalSpacing: CGFloat = 8
    /// Нижний отступ палитры
    public static let bottomPadding: CGFloat = 4
    /// Сдвиг на 8 бит (для декодирования hex-цвета)
    public static let hexShift8: UInt64 = 8
    /// Сдвиг на 16 бит (для декодирования hex-цвета)
    public static let hexShift16: UInt64 = 16
    /// Сдвиг на 24 бита (для декодирования hex-цвета)
    public static let hexShift24: UInt64 = 24
    /// Сдвиг на 4 бита (для декодирования hex-цвета)
    public static let hexShift4: UInt64 = 4
    /// Маска для 4 бит (0xF)
    public static let mask4bit: UInt64 = 0xF
    /// Маска для 8 бит (0xFF)
    public static let mask8bit: UInt64 = 0xFF
    /// Маска для 12 бит (0xFFF)
    public static let mask12bit: UInt64 = 0xFFF
    /// Маска для 8 бит (0xFF, дублирует mask8bit)
    public static let maskFF: UInt64 = 0xFF
    /// Маска для 4 бит (0xF, дублирует mask4bit)
    public static let maskF: UInt64 = 0xF
    /// Accessibility trait для выбранного цвета
    public static let selectedTrait: AccessibilityTraits = .isSelected
    /// Список hex-кодов доступных цветов.
    public static let palette: [String] = [
        "ef476f", "f78c6b", "ffd166", "83d483", "06d6a0",
        "0cb0a9", "118ab2"
    ]
    /// Значение компоненты цвета по умолчанию (0), используется для инициализации цвета, если hex-строка некорректна.
    public static let defaultComponent: UInt64 = 0
    /// Основной цвет кнопки (primary, красная компонента)
    public static let primaryRed: Double = 0.533
    /// Основной цвет кнопки (primary, зелёная компонента)
    public static let primaryGreen: Double = 0.886
    /// Основной цвет кнопки (primary, синяя компонента)
    public static let primaryBlue: Double = 0.776
    /// Вторичный цвет кнопки (secondary, красная компонента)
    public static let secondaryRed: Double = 1.0
    /// Вторичный цвет кнопки (secondary, зелёная компонента)
    public static let secondaryGreen: Double = 0.510
    /// Вторичный цвет кнопки (secondary, синяя компонента)
    public static let secondaryBlue: Double = 0.490
    /// Красная компонента secondaryText (dark). Используется для вторичного текста в темной теме.
    public static let secondaryTextRed: Double = 0.7
    /// Зеленая компонента secondaryText (dark). Используется для вторичного текста в темной теме.
    public static let secondaryTextGreen: Double = 0.7
    /// Синяя компонента secondaryText (dark). Используется для вторичного текста в темной теме.
    public static let secondaryTextBlue: Double = 0.75
    /// Яркость secondaryText (light). Используется для вторичного текста в светлой теме.
    public static let secondaryTextWhite: Double = 0.5
    /// Красная компонента destructive (dark). Используется для destructive-действий в темной теме.
    public static let destructiveRed: Double = 1.0
    /// Зеленая компонента destructive (dark). Используется для destructive-действий в темной теме.
    public static let destructiveGreen: Double = 0.3
    /// Синяя компонента destructive (dark). Используется для destructive-действий в темной теме.
    public static let destructiveBlue: Double = 0.3
    /// Красная компонента destructive (light). Используется для destructive-действий в светлой теме.
    public static let destructiveLightRed: Double = 0.95
    /// Зеленая компонента destructive (light). Используется для destructive-действий в светлой теме.
    public static let destructiveLightGreen: Double = 0.23
    /// Синяя компонента destructive (light). Используется для destructive-действий в светлой теме.
    public static let destructiveLightBlue: Double = 0.23
    /// Красная компонента link (dark). Используется для ссылок в темной теме.
    public static let linkRed: Double = 0.4
    /// Зеленая компонента link (dark). Используется для ссылок в темной теме.
    public static let linkGreen: Double = 0.7
    /// Синяя компонента link (dark). Используется для ссылок в темной теме.
    public static let linkBlue: Double = 1.0
    /// Красная компонента link (light). Используется для ссылок в светлой теме.
    public static let linkLightRed: Double = 0.0
    /// Зеленая компонента link (light). Используется для ссылок в светлой теме.
    public static let linkLightGreen: Double = 0.48
    /// Синяя компонента link (light). Используется для ссылок в светлой теме.
    public static let linkLightBlue: Double = 1.0
    /// Красная компонента фона (dark). Используется для фона в темной теме.
    public static let backgroundDarkRed: Double = 0.09
    /// Зеленая компонента фона (dark). Используется для фона в темной теме.
    public static let backgroundDarkGreen: Double = 0.09
    /// Синяя компонента фона (dark). Используется для фона в темной теме.
    public static let backgroundDarkBlue: Double = 0.11
    /// Красная компонента white (dark). Используется для белого цвета в темной теме.
    public static let whiteDarkRed: Double = 0.13
    /// Зеленая компонента white (dark). Используется для белого цвета в темной теме.
    public static let whiteDarkGreen: Double = 0.13
    /// Синяя компонента white (dark). Используется для белого цвета в темной теме.
    public static let whiteDarkBlue: Double = 0.15
}
