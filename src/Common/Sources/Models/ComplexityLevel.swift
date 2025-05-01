import Foundation

/// Уровень сложности для simplify-операций
public enum ComplexityLevel: String, Codable, CaseIterable, Equatable {
    case schoolchild = "schoolchild"
    case teenager = "teenager"
    case student = "student"
    case adult = "adult"
}
