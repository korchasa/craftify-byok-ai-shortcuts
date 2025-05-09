import SwiftUI

/// Фабрика централизованных палитр для ShareExtension, выбирает палитру по ColorScheme.
public enum ShareExtensionColorPaletteFactory {
    /// Возвращает палитру для заданной схемы (light/dark).
    /// - Parameter scheme: Текущая цветовая схема устройства.
    /// - Returns: Реализация ShareExtensionColorPaletteProviding для схемы.
    public static func palette(for scheme: ColorScheme) -> ShareExtensionColorPaletteProviding {
        switch scheme {
        case .light:
            return LightShareExtensionColorPalette()
        case .dark:
            return DarkShareExtensionColorPalette()
        @unknown default:
            return LightShareExtensionColorPalette()
        }
    }
}
