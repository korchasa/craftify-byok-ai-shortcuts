import Foundation

// import Common
import XCTest

// Импорт функции isHttpURL

/// Тесты моделей операций Craftify
public final class OperationModelsTests: XCTestCase {
    /// Проверяет rawValue у OperationType
    public func testOperationTypeRawValues() {
        XCTAssertEqual(OperationKind.translate.rawValue, "translate")
        XCTAssertEqual(OperationKind.simplify.rawValue, "simplify")
        XCTAssertEqual(OperationKind.correct.rawValue, "correct")
        XCTAssertEqual(OperationKind.explain.rawValue, "explain")
    }

    /// Проверяет Codable для TranslateParams
    public func testTranslateParamsCodable() throws {
        let params = TranslateParams(targetLanguage: "ru")
        let data = try JSONEncoder().encode(params)
        let decoded = try JSONDecoder().decode(TranslateParams.self, from: data)
        XCTAssertEqual(decoded, params)
    }

    /// Проверяет Codable для SimplifyParams
    public func testSimplifyParamsCodable() throws {
        let params = SimplifyParams(complexityLevel: .schoolchild)
        let data = try JSONEncoder().encode(params)
        let decoded = try JSONDecoder().decode(SimplifyParams.self, from: data)
        XCTAssertEqual(decoded, params)
    }

    /// Проверяет Codable для CorrectParams
    public func testCorrectParamsCodable() throws {
        let params = CorrectParams()
        let data = try JSONEncoder().encode(params)
        let decoded = try JSONDecoder().decode(CorrectParams.self, from: data)
        XCTAssertEqual(decoded, params)
    }

    /// Проверяет Codable для ExplainParams
    public func testExplainParamsCodable() throws {
        let params = ExplainParams(detailLevel: .adult)
        let data = try JSONEncoder().encode(params)
        let decoded = try JSONDecoder().decode(ExplainParams.self, from: data)
        XCTAssertEqual(decoded, params)
    }

    /// Проверяет Codable для InventoryOperation
    public func testInventoryOperationCodable() throws {
        let params = TranslateParams(targetLanguage: "en")
        let paramsData = try JSONEncoder().encode(params)
        let operation = InventoryOperation(operation: .translate, params: paramsData)
        let data = try JSONEncoder().encode(operation)
        let decoded = try JSONDecoder().decode(InventoryOperation.self, from: data)
        XCTAssertEqual(decoded.operation, operation.operation)
        let decodedParams = try JSONDecoder().decode(TranslateParams.self, from: decoded.params)
        XCTAssertEqual(decodedParams, params)
    }

    /// Проверяет сериализацию/десериализацию colorHex в InventoryOperation
    public func testInventoryOperationColorHexCodable() throws {
        let params = TranslateParams(targetLanguage: "fr")
        let paramsData = try JSONEncoder().encode(params)
        let colorHex = "3288bd"
        let operation = InventoryOperation(operation: .translate, params: paramsData, colorHex: colorHex)
        let data = try JSONEncoder().encode(operation)
        let decoded = try JSONDecoder().decode(InventoryOperation.self, from: data)
        XCTAssertEqual(decoded.colorHex, colorHex)
    }

    /// Проверяет режим обработки результата по умолчанию (clipboard)
    public func testDefaultResultMode() {
        let translateOp = TranslateOperation()
        let simplifyOp = SimplifyOperation()
        let correctOp = CorrectOperation()
        XCTAssertEqual(translateOp.resultMode, .clipboard)
        XCTAssertEqual(simplifyOp.resultMode, .clipboard)
        XCTAssertEqual(correctOp.resultMode, .clipboard)
    }

    /// Проверяет режим обработки результата для ExplainOperation (display)
    public func testExplainOperationResultMode() {
        let explainOp = ExplainOperation()
        XCTAssertEqual(explainOp.resultMode, .display)
    }

    /// Проверяет режим обработки результата для SummarizeOperation (display)
    public func testSummarizeOperationResultMode() {
        let summarizeOp = SummarizeOperation()
        XCTAssertEqual(summarizeOp.resultMode, .display)
    }

    /// Проверяет соответствие SF Symbol для каждого типа операции
    public func testOperationKindSFSymbols() {
        XCTAssertEqual(OperationKind.translate.sfSymbol, "globe")
        XCTAssertEqual(OperationKind.simplify.sfSymbol, "line.3.horizontal.decrease")
        XCTAssertEqual(OperationKind.correct.sfSymbol, "checkmark.circle")
        XCTAssertEqual(OperationKind.explain.sfSymbol, "lightbulb")
        XCTAssertEqual(OperationKind.summarize.sfSymbol, "list.bullet")
    }

    /// Проверяет определение строки как HTTP(S) URL
    public func testIsHttpURL() {
        XCTAssertTrue(OperationInput.isHttpURL(string: "http://example.com"))
        XCTAssertTrue(OperationInput.isHttpURL(string: "https://example.com"))
        XCTAssertFalse(OperationInput.isHttpURL(string: "ftp://example.com"))
        XCTAssertFalse(OperationInput.isHttpURL(string: "example.com"))
        XCTAssertFalse(OperationInput.isHttpURL(string: "not a url"))
        XCTAssertFalse(OperationInput.isHttpURL(string: ""))
    }

    /// Очистка ресурсов (stub)
    deinit { /* nothing to cleanup */ }

    // MARK: - resolveInput Tests

    func testSummarizeOperation_resolveInput_withText_returnsText() async throws {
        let op = SummarizeOperation(textFetcher: DummyTextFetcher())
        let input = OperationInput(text: "Some text")
        let result = try await op.resolveInput(input: input)
        XCTAssertEqual(result, "Some text")
    }

    func testSummarizeOperation_resolveInput_withURL_fetchesText() async throws {
        let op = SummarizeOperation(textFetcher: DummyTextFetcher())
        let input = OperationInput(url: "https://test.com")
        let result = try await op.resolveInput(input: input)
        XCTAssertEqual(result, "FAKE_TEXT")
    }

    func testSummarizeOperation_resolveInput_noInput_throws() async {
        let op = SummarizeOperation(textFetcher: DummyTextFetcher())
        let input = OperationInput(url: nil, text: nil)
        do {
            _ = try await op.resolveInput(input: input)
            XCTFail("Ожидалось исключение, но оно не было выброшено")
        } catch {
            // Ожидаемое поведение: ошибка выброшена
        }
    }

    func testTranslateOperation_resolveInput_withText_returnsText() throws {
        let op = TranslateOperation()
        let input = OperationInput(text: "Text")
        let result = try op.resolveInput(input: input)
        XCTAssertEqual(result, "Text")
    }

    func testTranslateOperation_resolveInput_withURL_throws() {
        let op = TranslateOperation()
        let input = OperationInput(url: "https://test.com")
        XCTAssertThrowsError(try op.resolveInput(input: input)) { error in
            guard let userError = error as? UserFacingError else {
                XCTFail("Ожидался UserFacingError, получено: \(type(of: error))")
                return
            }
            XCTAssertEqual(userError.messageKey, .errorUrlNotSupported)
        }
    }

    func testSimplifyOperation_resolveInput_withText_returnsText() throws {
        let op = SimplifyOperation()
        let input = OperationInput(text: "Text")
        let result = try op.resolveInput(input: input)
        XCTAssertEqual(result, "Text")
    }

    func testSimplifyOperation_resolveInput_withURL_throws() {
        let op = SimplifyOperation()
        let input = OperationInput(url: "https://test.com")
        XCTAssertThrowsError(try op.resolveInput(input: input)) { error in
            guard let userError = error as? UserFacingError else {
                XCTFail("Ожидался UserFacingError, получено: \(type(of: error))")
                return
            }
            XCTAssertEqual(userError.messageKey, .errorUrlNotSupported)
        }
    }

    func testCorrectOperation_resolveInput_withText_returnsText() throws {
        let op = CorrectOperation()
        let input = OperationInput(text: "Text")
        let result = try op.resolveInput(input: input)
        XCTAssertEqual(result, "Text")
    }

    func testCorrectOperation_resolveInput_withURL_throws() {
        let op = CorrectOperation()
        let input = OperationInput(url: "https://test.com")
        XCTAssertThrowsError(try op.resolveInput(input: input)) { error in
            guard let userError = error as? UserFacingError else {
                XCTFail("Ожидался UserFacingError, получено: \(type(of: error))")
                return
            }
            XCTAssertEqual(userError.messageKey, .errorUrlNotSupported)
        }
    }

    func testExplainOperation_resolveInput_withText_returnsText() throws {
        let op = ExplainOperation()
        let input = OperationInput(text: "Text")
        let result = try op.resolveInput(input: input)
        XCTAssertEqual(result, "Text")
    }

    func testExplainOperation_resolveInput_withURL_throws() {
        let op = ExplainOperation()
        let input = OperationInput(url: "https://test.com")
        XCTAssertThrowsError(try op.resolveInput(input: input)) { error in
            guard let userError = error as? UserFacingError else {
                XCTFail("Ожидался UserFacingError, получено: \(type(of: error))")
                return
            }
            XCTAssertEqual(userError.messageKey, .errorUrlNotSupported)
        }
    }

    /// Проверяет, что смена языка влияет на system-сообщение в makeMessages для SummarizeOperation и ExplainOperation
    func testSystemMessageReflectsCurrentLanguage() {
        let manager = AppSettingsManager(suiteName: "group.dev.korchasa.Craftify")
        manager.nativeLanguage = "English" // Ensure english name
        let summarizeOp = SummarizeOperation()
        let explainOp = ExplainOperation()
        let input = OperationInput()
        let messagesSumEN = summarizeOp.makeMessages(input: input, text: "dummy")
        let messagesExpEN = explainOp.makeMessages(input: input, text: "dummy")
        let enSystemContains = { (messages: [LLMMessage], keyword: String) -> Bool in
            messages.first(where: { $0.role == .system })?.content.contains(keyword) ?? false
        }
        XCTAssertTrue(enSystemContains(messagesSumEN, "English"))
        XCTAssertTrue(enSystemContains(messagesExpEN, "English"))

        manager.nativeLanguage = "Russian"
        let messagesSumRU = summarizeOp.makeMessages(input: input, text: "dummy")
        let messagesExpRU = explainOp.makeMessages(input: input, text: "dummy")
        XCTAssertTrue(enSystemContains(messagesSumRU, "Russian") || enSystemContains(messagesSumRU, "Русский"))
        XCTAssertTrue(enSystemContains(messagesExpRU, "Russian") || enSystemContains(messagesExpRU, "Русский"))
    }
}

// MARK: - DummyTextFetcher for SummarizeOperation tests

private final class DummyTextFetcher: TextFetching {
    func fetchText(from url: String) async throws -> String { "FAKE_TEXT" }
    func fetchAndExtractText(from urlString: String, completion: @escaping (Result<String, Error>) -> Void) {
        completion(.success("FAKE_TEXT"))
    }
}
