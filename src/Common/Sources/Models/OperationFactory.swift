import Foundation

/// Фабрика операций: список доступных OperationKind и конструктор OperationType
public enum OperationFactory {
    /// Все поддерживаемые виды операций
    public static let allKinds: [OperationKind] = OperationKind.allCases

    /// Создает конкретную реализацию OperationType по OperationKind
    public static func make(kind: OperationKind, logManager: LogManagerShared? = nil) -> OperationType {
        switch kind {
        case .translate: TranslateOperation()
        case .simplify: SimplifyOperation()
        case .correct: CorrectOperation()
        case .explain: ExplainOperation()
        case .summarize: SummarizeOperation(logManager: logManager)
        }
    }
}
