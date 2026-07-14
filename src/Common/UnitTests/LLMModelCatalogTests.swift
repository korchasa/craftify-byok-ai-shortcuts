import XCTest

/// Тесты каталога моделей: у каждого провайдера задана непустая модель по умолчанию
final class LLMModelCatalogTests: XCTestCase {
    func testEveryProviderHasNonEmptyDefaultModel() {
        for provider in LLMProvider.allCases {
            let model = LLMModelCatalog.defaultModel(for: provider)
            XCTAssertFalse(model.isEmpty, "Empty default model for \(provider.rawValue)")
            XCTAssertEqual(model, model.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
}
