import XCTest

/// Тесты каталога моделей: у каждого провайдера непустой список, модель по умолчанию — из списка
final class LLMModelCatalogTests: XCTestCase {
    func testEveryProviderHasCuratedListWithValidDefault() {
        for provider in LLMProvider.allCases {
            let models = LLMModelCatalog.curatedModels(for: provider)
            XCTAssertFalse(models.isEmpty, "Empty model list for \(provider.rawValue)")
            XCTAssertEqual(models.count, Set(models).count, "Duplicate models for \(provider.rawValue)")
            for model in models {
                XCTAssertFalse(model.isEmpty)
                XCTAssertEqual(model, model.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            XCTAssertEqual(LLMModelCatalog.defaultModel(for: provider), models[0])
        }
    }
}
