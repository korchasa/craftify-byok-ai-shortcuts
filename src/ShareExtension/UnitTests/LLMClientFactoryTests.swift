import XCTest

/// Тесты фабрики LLM-клиентов: внедрение выбранной пользователем модели
public final class LLMClientFactoryTests: XCTestCase {
    private let suite = "test.craftify.factory-model"

    override public func setUp() {
        super.setUp()
        UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
    }

    override public func tearDown() {
        UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
        super.tearDown()
    }

    public func testMake_InjectsStoredModel() {
        let settings = AppSettingsManager(suiteName: suite)
        settings.setModel("gpt-4.1-mini", for: .openAI)

        let openAI = LLMClientFactory.make(provider: .openAI, settings: settings)
        XCTAssertEqual((openAI as? OpenAIAPIClient)?.model, "gpt-4.1-mini")

        // Без сохранённого значения клиент получает модель по умолчанию
        let claude = LLMClientFactory.make(provider: .claude, settings: settings)
        XCTAssertEqual((claude as? ClaudeAPIClient)?.model, LLMModelCatalog.defaultModel(for: .claude))
        let mistral = LLMClientFactory.make(provider: .mistral, settings: settings)
        XCTAssertEqual((mistral as? MistralAPIClient)?.model, LLMModelCatalog.defaultModel(for: .mistral))
        let openRouter = LLMClientFactory.make(provider: .openRouter, settings: settings)
        XCTAssertEqual((openRouter as? OpenRouterAPIClient)?.model, LLMModelCatalog.defaultModel(for: .openRouter))
    }
}
