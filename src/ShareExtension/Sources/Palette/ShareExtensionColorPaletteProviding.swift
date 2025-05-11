import SwiftUI

/// Протокол централизованной палитры цветов для ShareExtension.
public protocol ShareExtensionColorPaletteProviding: ColorPaletteProviding {
    /// Цвет фона основного экрана
    func background() -> Color
    /// Цвет основного текста
    func primaryText() -> Color
    /// Цвет вторичного текста
    func secondaryText() -> Color
    /// Цвет основного действия (фон primary-кнопки)
    func primaryButton() -> Color
    /// Цвет текста на primary-кнопке
    func primaryButtonText() -> Color
    /// Цвет вторичного действия (фон secondary-кнопки)
    func secondaryButton() -> Color
    /// Цвет текста на secondary-кнопке
    func secondaryButtonText() -> Color
    /// Цвет для destructive-действий
    func destructive() -> Color
    /// Цвет для ссылок
    func link() -> Color
    /// Цвет символа операции (всегда темно-серый)
    func operationSymbolColor() -> Color
}
