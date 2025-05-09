import SwiftUI

/// Ключ для централизованной палитры цветов ShareExtension в Environment
private struct ShareExtensionColorPaletteKey: EnvironmentKey {
    static let defaultValue: ShareExtensionColorPaletteProviding = LightShareExtensionColorPalette()
}

/// Тип-алиас для соответствия требованиям SwiftLint (file_name)
public typealias ShareExtensionColorPaletteEnvironment = EnvironmentValues

/// Расширение для доступа к централизованной палитре через Environment
public extension ShareExtensionColorPaletteEnvironment {
    /// Централизованная палитра цветов ShareExtension
    var shareExtensionColorPalette: ShareExtensionColorPaletteProviding {
        get { self[ShareExtensionColorPaletteKey.self] }
        set { self[ShareExtensionColorPaletteKey.self] = newValue }
    }
}
