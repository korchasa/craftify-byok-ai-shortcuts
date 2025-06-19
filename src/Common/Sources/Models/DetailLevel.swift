import Foundation

/// Уровень детализации для explain-операций
public enum DetailLevel: String, Codable, CaseIterable, Equatable {
    case schoolchild = "schoolchild"
    case teenager = "teenager"
    case adult = "adult"
}
