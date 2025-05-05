import Foundation

/// Supported operation types for Craftify
public enum OperationKind: String, Codable, CaseIterable, Equatable {
    case correct = "correct"
    case explain = "explain"
    case simplify = "simplify"
    case translate = "translate"
    case summarize = "summarize"

    /// SF Symbol name for each operation type
    public var sfSymbol: String {
        switch self {
        case .translate: "globe"
        case .simplify: "line.3.horizontal.decrease"
        case .correct: "checkmark.circle"
        case .explain: "lightbulb"
        case .summarize: "list.bullet"
        }
    }
}
