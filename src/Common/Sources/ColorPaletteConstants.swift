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
    private static let RGB12BitMultiplierValue: UInt64 = 17
    /// Множитель для 12-битного RGB (17), используется для преобразования компоненты цвета из 12-битного формата.
    public static let rgb12BitMultiplier: UInt64 = RGB12BitMultiplierValue
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
        "9e0142", "d53e4f", "f46d43", "fdae61", "fee08b",
        "e6f598", "abdda4", "66c2a5", "3288bd", "5e4fa2"
    ]
    /// Значение компоненты цвета по умолчанию (0), используется для инициализации цвета, если hex-строка некорректна.
    public static let defaultComponent: UInt64 = 0
}
