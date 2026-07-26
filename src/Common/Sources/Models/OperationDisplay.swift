import Foundation

// [REF:fr:ux.operation-setting-parity]
/// Подписи операции для интерфейса: название и значение настройки.
/// Настройку пользователь задаёт на экране списка операций, а на экране выбора
/// трансформации только видит и использует её, поэтому обе строки собираются
/// в одном месте — иначе экраны показывают одно и то же значение по-разному.
public enum OperationDisplay {
    /// Локализованное название операции
    /// - Parameter kind: Тип операции
    /// - Returns: Название операции на языке интерфейса
    public static func title(for kind: OperationKind) -> String {
        switch kind {
        case .translate: L10n.operationLabelTranslate
        case .simplify: L10n.operationLabelSimplify
        case .correct: L10n.operationLabelCorrect
        case .explain: L10n.operationLabelExplain
        case .summarize: L10n.operationLabelSummarize
        }
    }

    /// Значение настройки операции в том виде, в каком его задали в списке
    /// - Parameter operation: Операция инвентаря
    /// - Returns: Локализованное значение настройки; пустая строка, если у операции нет настраиваемых параметров
    public static func settingValue(for operation: InventoryOperation) -> String {
        switch operation.operation {
        case .translate:
            guard let params = try? JSONDecoder().decode(TranslateParams.self, from: operation.params) else {
                return ""
            }
            return SupportedLanguages.all.first { $0.code == params.targetLanguage }?.name ?? params.targetLanguage
        case .summarize:
            guard let params = try? JSONDecoder().decode(SummarizeParams.self, from: operation.params) else {
                return ""
            }
            return SummarizeLengthDisplay.label(for: params.length)
        case .simplify, .correct, .explain:
            return ""
        }
    }
}
