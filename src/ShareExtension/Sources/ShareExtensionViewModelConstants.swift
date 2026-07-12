import Foundation

/// Константы для логики ShareExtensionViewModel
public enum ShareExtensionViewModelConstants {
    /// Максимальная длина входного текста; более длинный вход обрезается
    public static let maxInputTextLength = ShareExtensionManager.maxTextLength
    /// Количество наносекунд в одной секунде
    public static let nanosecondsPerSecond: UInt64 = 1_000_000_000
}
