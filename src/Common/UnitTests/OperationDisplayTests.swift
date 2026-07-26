import XCTest

/// Подписи операции для интерфейса: экран списка и экран выбора трансформации
/// должны показывать одно и то же значение настройки
public final class OperationDisplayTests: XCTestCase {
    public func testTranslateShowsNativeLanguageName() throws {
        let params = try JSONEncoder().encode(TranslateParams(targetLanguage: "en"))
        let operation = InventoryOperation(operation: .translate, params: params)
        XCTAssertEqual(OperationDisplay.settingValue(for: operation), "English")
    }

    public func testTranslateFallsBackToRawCodeForUnknownLanguage() throws {
        let params = try JSONEncoder().encode(TranslateParams(targetLanguage: "zzz"))
        let operation = InventoryOperation(operation: .translate, params: params)
        XCTAssertEqual(OperationDisplay.settingValue(for: operation), "zzz")
    }

    /// Каноническое значение уходит в промпт, а пользователю показывается
    /// локализованная подпись — сырую строку на экране видеть нельзя
    public func testSummarizeShowsLocalizedLabelNotCanonicalValue() throws {
        let params = try JSONEncoder().encode(SummarizeParams(length: "9-10 sentences"))
        let operation = InventoryOperation(operation: .summarize, params: params)
        let value = OperationDisplay.settingValue(for: operation)
        XCTAssertEqual(value, SummarizeLengthDisplay.label(for: "9-10 sentences"))
        XCTAssertNotEqual(value, "9-10 sentences")
    }

    public func testOperationsWithoutParamsHaveEmptySettingValue() {
        for kind in [OperationKind.simplify, .correct, .explain] {
            let operation = InventoryOperation(operation: kind, params: Data())
            XCTAssertEqual(OperationDisplay.settingValue(for: operation), "")
        }
    }

    public func testBrokenParamsDoNotCrashAndYieldEmptyValue() {
        let operation = InventoryOperation(operation: .translate, params: Data())
        XCTAssertEqual(OperationDisplay.settingValue(for: operation), "")
    }

    public func testTitleIsNonEmptyForEveryKind() {
        for kind in OperationKind.allCases {
            XCTAssertFalse(OperationDisplay.title(for: kind).isEmpty)
        }
    }
}
