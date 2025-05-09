import SwiftUI

/// Ключ для централизованной палитры цветов MainApp в Environment
private struct ColorPaletteKey: EnvironmentKey {
    static let defaultValue: MainAppColorPaletteProviding = LightMainAppColorPalette()
}

/// Тип-алиас для соответствия требованиям SwiftLint (file_name)
public typealias ColorPaletteEnvironment = EnvironmentValues

/// Расширение для доступа к централизованной палитре через Environment
public extension ColorPaletteEnvironment {
    /// Централизованная палитра цветов MainApp
    var colorPalette: MainAppColorPaletteProviding {
        get { self[ColorPaletteKey.self] }
        set { self[ColorPaletteKey.self] = newValue }
    }
}
