import Foundation

/// Константы для логики прогресса ShareExtensionViewModel
public enum ShareExtensionViewModelConstants {
    /// Шаг прогресса при эмуляции
    public static let progressStep: Double = 0.1
    /// Интервал обновления прогресса (сек)
    public static let progressInterval: TimeInterval = 0.3
    /// Максимальный прогресс до завершения (0..1)
    public static let maxProgress: Double = 0.9
    /// Значение прогресса при завершении
    public static let completeProgress: Double = 1.0
}
