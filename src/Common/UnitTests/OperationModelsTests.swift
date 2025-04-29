@testable import Common
import Nimble
import XCTest

/// Тесты моделей операций Craftify
public final class OperationModelsTests: XCTestCase {
    /// Проверяет rawValue у OperationType
    public func testOperationTypeRawValues() {
        expect(OperationType.translate.rawValue) == "translate"
        expect(OperationType.simplify.rawValue) == "simplify"
        expect(OperationType.correct.rawValue) == "correct"
        expect(OperationType.explain.rawValue) == "explain"
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
        let params = SimplifyParams(complexityLevel: .beginner)
        let data = try JSONEncoder().encode(params)
        let decoded = try JSONDecoder().decode(SimplifyParams.self, from: data)
        expect(decoded) == params
    }

    /// Проверяет Codable для CorrectParams
    public func testCorrectParamsCodable() throws {
        let styleLevel = 2
        let params = CorrectParams(stylePreservationLevel: styleLevel)
        let data = try JSONEncoder().encode(params)
        let decoded = try JSONDecoder().decode(CorrectParams.self, from: data)
        expect(decoded) == params
    }

    /// Проверяет Codable для ExplainParams
    public func testExplainParamsCodable() throws {
        let params = ExplainParams(detailLevel: .advanced)
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

    /// Очистка ресурсов (stub)
    deinit { /* nothing to cleanup */ }
}
