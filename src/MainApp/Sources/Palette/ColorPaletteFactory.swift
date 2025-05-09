import SwiftUI

/// Фабрика централизованных палитр для MainApp, выбирает палитру по ColorScheme.
public enum ColorPaletteFactory {
    /// Возвращает палитру для заданной схемы (light/dark).
    /// - Parameter scheme: Текущая цветовая схема устройства.
    /// - Returns: Реализация MainAppColorPaletteProviding для схемы.
    public static func palette(for scheme: ColorScheme) -> MainAppColorPaletteProviding {
        switch scheme {
        case .light:
            return LightMainAppColorPalette()
        case .dark:
            return DarkMainAppColorPalette()
        @unknown default:
            return LightMainAppColorPalette()
        }
    }
}
