import Foundation

/// Уровень детализации для explain-операций
public enum DetailLevel: String, Codable, CaseIterable, Equatable {
    case advanced = "advanced"
    case beginner = "beginner"
    case intermediate = "intermediate"
}
