@testable import Common
import Nimble
import XCTest

/// Тесты моделей операций Craftify
public final class OperationModelsTests: XCTestCase {
    /// Проверяет rawValue у OperationType
    public func testOperationTypeRawValues() {
        expect(OperationKind.translate.rawValue) == "translate"
        expect(OperationKind.simplify.rawValue) == "simplify"
        expect(OperationKind.correct.rawValue) == "correct"
        expect(OperationKind.explain.rawValue) == "explain"
    }

    /// Проверяет Codable для TranslateParams
    public func testTranslateParamsCodable() throws {
        let params = TranslateParams(targetLanguage: "ru")
        let data = try JSONEncoder().encode(params)
        let decoded = try JSONDecoder().decode(TranslateParams.self, from: data)
        expect(decoded) == params
    }

    /// Проверяет Codable для SimplifyParams
    public func testSimplifyParamsCodable() throws {
        let params = SimplifyParams(complexityLevel: .schoolchild)
        let data = try JSONEncoder().encode(params)
        let decoded = try JSONDecoder().decode(SimplifyParams.self, from: data)
        expect(decoded) == params
    }

    /// Проверяет Codable для CorrectParams
    public func testCorrectParamsCodable() throws {
        let params = CorrectParams()
        let data = try JSONEncoder().encode(params)
        let decoded = try JSONDecoder().decode(CorrectParams.self, from: data)
        expect(decoded) == params
    }

    /// Проверяет Codable для ExplainParams
    public func testExplainParamsCodable() throws {
        let params = ExplainParams(detailLevel: .adult)
        let data = try JSONEncoder().encode(params)
        let decoded = try JSONDecoder().decode(ExplainParams.self, from: data)
        expect(decoded) == params
    }

    /// Проверяет Codable для InventoryOperation
    public func testInventoryOperationCodable() throws {
        let params = TranslateParams(targetLanguage: "en")
        let paramsData = try JSONEncoder().encode(params)
        let operation = InventoryOperation(operation: .translate, params: paramsData, promptTemplate: "Translate: {text}")
        let data = try JSONEncoder().encode(operation)
        let decoded = try JSONDecoder().decode(InventoryOperation.self, from: data)
        expect(decoded.operation) == operation.operation
        expect(decoded.promptTemplate) == operation.promptTemplate
        let decodedParams = try JSONDecoder().decode(TranslateParams.self, from: decoded.params)
        expect(decodedParams) == params
    }

    /// Проверяет сериализацию/десериализацию colorHex в InventoryOperation
    public func testInventoryOperationColorHexCodable() throws {
        let params = TranslateParams(targetLanguage: "fr")
        let paramsData = try JSONEncoder().encode(params)
        let colorHex = "3288bd"
        let operation = InventoryOperation(operation: .translate, params: paramsData, promptTemplate: "Translate: {text}", colorHex: colorHex)
        let data = try JSONEncoder().encode(operation)
        let decoded = try JSONDecoder().decode(InventoryOperation.self, from: data)
        expect(decoded.colorHex) == colorHex
    }

    /// Проверяет режим обработки результата по умолчанию (clipboard)
    public func testDefaultResultMode() {
        let translateOp = TranslateOperation()
        let simplifyOp = SimplifyOperation()
        let correctOp = CorrectOperation()
        expect(translateOp.resultMode) == .clipboard
        expect(simplifyOp.resultMode) == .clipboard
        expect(correctOp.resultMode) == .clipboard
    }

    /// Проверяет режим обработки результата для ExplainOperation (display)
    public func testExplainOperationResultMode() {
        let explainOp = ExplainOperation()
        expect(explainOp.resultMode) == .display
    }

    /// Проверяет режим обработки результата для SummarizeOperation (display)
    public func testSummarizeOperationResultMode() {
        let summarizeOp = SummarizeOperation()
        expect(summarizeOp.resultMode) == .display
    }

    /// Очистка ресурсов (stub)
    deinit { /* nothing to cleanup */ }

    // MARK: - resolveInput Tests

    func testSummarizeOperation_resolveInput_withText_returnsText() async throws {
        let op = SummarizeOperation(textFetcher: DummyTextFetcher())
        let input = OperationInput(text: "Some text")
        let result = try await op.resolveInput(input: input)
        expect(result) == "Some text"
    }

    func testSummarizeOperation_resolveInput_withURL_fetchesText() async throws {
        let op = SummarizeOperation(textFetcher: DummyTextFetcher())
        let input = OperationInput(url: "https://test.com")
        let result = try await op.resolveInput(input: input)
        expect(result) == "FAKE_TEXT"
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
        expect(result) == "Text"
    }

    func testTranslateOperation_resolveInput_withURL_throws() {
        let op = TranslateOperation()
        let input = OperationInput(url: "https://test.com")
        expect {
            _ = try op.resolveInput(input: input)
        }.to(throwError { (error: Error) in
            let nsError = error as NSError
            expect(nsError.domain) == "TranslateOperation"
        })
    }

    func testSimplifyOperation_resolveInput_withText_returnsText() throws {
        let op = SimplifyOperation()
        let input = OperationInput(text: "Text")
        let result = try op.resolveInput(input: input)
        expect(result) == "Text"
    }

    func testSimplifyOperation_resolveInput_withURL_throws() {
        let op = SimplifyOperation()
        let input = OperationInput(url: "https://test.com")
        expect {
            _ = try op.resolveInput(input: input)
        }.to(throwError { (error: Error) in
            let nsError = error as NSError
            expect(nsError.domain) == "SimplifyOperation"
        })
    }

    func testCorrectOperation_resolveInput_withText_returnsText() throws {
        let op = CorrectOperation()
        let input = OperationInput(text: "Text")
        let result = try op.resolveInput(input: input)
        expect(result) == "Text"
    }

    func testCorrectOperation_resolveInput_withURL_throws() {
        let op = CorrectOperation()
        let input = OperationInput(url: "https://test.com")
        expect {
            _ = try op.resolveInput(input: input)
        }.to(throwError { (error: Error) in
            let nsError = error as NSError
            expect(nsError.domain) == "CorrectOperation"
        })
    }

    func testExplainOperation_resolveInput_withText_returnsText() throws {
        let op = ExplainOperation()
        let input = OperationInput(text: "Text")
        let result = try op.resolveInput(input: input)
        expect(result) == "Text"
    }

    func testExplainOperation_resolveInput_withURL_throws() {
        let op = ExplainOperation()
        let input = OperationInput(url: "https://test.com")
        expect {
            _ = try op.resolveInput(input: input)
        }.to(throwError { (error: Error) in
            let nsError = error as NSError
            expect(nsError.domain) == "ExplainOperation"
        })
    }
}

// MARK: - DummyTextFetcher for SummarizeOperation tests

private final class DummyTextFetcher: TextFetching {
    func fetchText(from url: String) async throws -> String { "FAKE_TEXT" }
    func fetchAndExtractText(from urlString: String, completion: @escaping (Result<String, Error>) -> Void) {
        completion(.success("FAKE_TEXT"))
    }
}
