import SwiftUI

/// Расширение для инициализации Color по hex-строке (например, "3288bd").
public extension Color {
    /// Создаёт цвет из hex-строки (например, "3288bd").
    /// - Parameter hex: Строка с hex-кодом цвета (например, "3288bd").
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case ColorPaletteConstants.rgb12BitLength: // RGB (12-bit)
            (a, r, g, b) = (
                ColorPaletteConstants.defaultAlpha,
                (int >> ColorPaletteConstants.hexShift8) * ColorPaletteConstants.rgb12BitMultiplier,
                (int >> ColorPaletteConstants.hexShift4 & ColorPaletteConstants.maskF) * ColorPaletteConstants.rgb12BitMultiplier,
                (int & ColorPaletteConstants.maskF) * ColorPaletteConstants.rgb12BitMultiplier
            )
        case ColorPaletteConstants.rgb24BitLength: // RGB (24-bit)
            (a, r, g, b) = (
                ColorPaletteConstants.defaultAlpha,
                int >> ColorPaletteConstants.hexShift16,
                int >> ColorPaletteConstants.hexShift8 & ColorPaletteConstants.maskFF,
                int & ColorPaletteConstants.maskFF
            )
        case ColorPaletteConstants.argb32BitLength: // ARGB (32-bit)
            (a, r, g, b) = (
                int >> ColorPaletteConstants.hexShift24,
                int >> ColorPaletteConstants.hexShift16 & ColorPaletteConstants.maskFF,
                int >> ColorPaletteConstants.hexShift8 & ColorPaletteConstants.maskFF,
                int & ColorPaletteConstants.maskFF
            )
        default:
            (a, r, g, b) = (ColorPaletteConstants.defaultAlpha, ColorPaletteConstants.defaultComponent, ColorPaletteConstants.defaultComponent, ColorPaletteConstants.defaultComponent)
        }
        self.init(
            .sRGB,
            red: Double(r) / ColorPaletteConstants.maxColorComponent,
            green: Double(g) / ColorPaletteConstants.maxColorComponent,
            blue: Double(b) / ColorPaletteConstants.maxColorComponent,
            opacity: Double(a) / ColorPaletteConstants.maxColorComponent
        )
    }

    /// Возвращает true, если цвет тёмный (используется для выбора цвета текста на фоне)
    var isDarkColor: Bool {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        #if canImport(UIKit)
            let uiColor = UIColor(self)
            uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #elseif canImport(AppKit)
            let nsColor = NSColor(self)
            nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif
        // Формула яркости: https://www.w3.org/TR/AERT/#color-contrast
        let redWeight: CGFloat = 299
        let greenWeight: CGFloat = 587
        let blueWeight: CGFloat = 114
        let brightnessDivisor: CGFloat = 1000
        let darkThreshold: CGFloat = 0.5
        let brightness = (red * redWeight + green * greenWeight + blue * blueWeight) / brightnessDivisor
        return brightness < darkThreshold
    }
}
