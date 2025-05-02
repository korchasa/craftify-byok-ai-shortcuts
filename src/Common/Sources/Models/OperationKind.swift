import Foundation

/// Supported operation types for Craftify
public enum OperationKind: String, Codable, CaseIterable, Equatable {
    case correct = "correct"
    case explain = "explain"
    case simplify = "simplify"
    case translate = "translate"
    case summarize = "summarize"
}
