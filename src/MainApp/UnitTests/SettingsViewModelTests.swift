// @testable import Common
import XCTest

@MainActor
public final class SettingsViewModelTests: XCTestCase {
    private var authManager: AuthManagerStub?
    private var viewModel: SettingsViewModel?

    override public func setUp() {
        super.setUp()
        authManager = AuthManagerStub(key: nil)
        viewModel = SettingsViewModel(authManager: authManager!, verifier: APIKeyVerifierStub())
    }

    override public func tearDown() {
        authManager = nil
        viewModel = nil
        super.tearDown()
    }

    public func testLoad_NoKey() async {
        guard let viewModel, let _ = authManager else { XCTFail("nil stub")
            return
        }
        await viewModel.load()
        XCTAssertEqual(viewModel.apiKey, "")
        XCTAssertFalse(viewModel.isKeyPresent)
        XCTAssertEqual(viewModel.maskedApiKey, shortMaskKey(nil))
    }

    public func testBeginEditing_StartsEmptyAndNeverExposesStoredKey() async {
        let storedKey = "sk-secret-key-1234567890"
        let editingViewModel = SettingsViewModel(
            authManager: AuthManagerStub(key: storedKey),
            verifier: APIKeyVerifierStub()
        )
        await editingViewModel.load()
        // Реальный ключ никогда не попадает в поле ввода — только короткая маска
        XCTAssertTrue(editingViewModel.isKeyPresent)
        XCTAssertEqual(editingViewModel.apiKey, "")
        XCTAssertEqual(editingViewModel.maskedApiKey, shortMaskKey(storedKey))
        XCTAssertFalse(editingViewModel.maskedApiKey.contains("secret-key"))
        // Редактирование начинается с пустого поля
        editingViewModel.beginEditing()
        XCTAssertTrue(editingViewModel.isEditingKey)
        XCTAssertEqual(editingViewModel.apiKey, "")
        // Отмена возвращает к маскированному состоянию
        editingViewModel.cancelEditing()
        XCTAssertFalse(editingViewModel.isEditingKey)
        XCTAssertEqual(editingViewModel.apiKey, "")
    }

    public func testModelSelection_PersistsPerProvider() {
        let suite = "test.craftify.model-selection"
        UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let settings = AppSettingsManager(suiteName: suite)
        let modelViewModel = SettingsViewModel(
            authManager: AuthManagerStub(key: nil),
            verifier: APIKeyVerifierStub(),
            settings: settings
        )
        modelViewModel.selectedProvider = .openAI
        // без сохранённого значения показывается модель по умолчанию
        XCTAssertEqual(modelViewModel.selectedModel, LLMModelCatalog.defaultModel(for: .openAI))
        modelViewModel.selectedModel = "gpt-4o"
        // смена провайдера показывает его собственную модель
        modelViewModel.selectedProvider = .claude
        XCTAssertEqual(modelViewModel.selectedModel, LLMModelCatalog.defaultModel(for: .claude))
        modelViewModel.selectedModel = "claude-3-5-haiku-latest"
        // возврат к первому провайдеру восстанавливает его выбор
        modelViewModel.selectedProvider = .openAI
        XCTAssertEqual(modelViewModel.selectedModel, "gpt-4o")
        XCTAssertEqual(settings.model(for: .claude), "claude-3-5-haiku-latest")
    }

    public func testProviderSwitchAndReturn_KeepsKey() async throws {
        // Arrange: как и настоящий Keychain, стаб читает ключ текущего провайдера
        // в момент запроса; у Claude ключа нет, и его ответ приходит с задержкой
        final class ProviderAwareAuthManagerStub: AuthManaging {
            private let settings: AppSettingsManager
            private let openAIKey: String
            init(settings: AppSettingsManager, openAIKey: String) {
                self.settings = settings
                self.openAIKey = openAIKey
            }

            func getAPIKey() async throws -> String? {
                let provider = settings.llmProvider
                if provider == .openAI {
                    return openAIKey
                }
                try? await Task.sleep(nanoseconds: 300_000_000)
                return nil
            }

            func setAPIKey(_ key: String) async throws {}
            func deleteAPIKey() async throws {}
            func maskedAPIKey(_ key: String?) -> String {
                maskKey(key)
            }
        }
        let storedKey = "sk-openai-key-1234567890"
        let suite = "test.craftify.provider-switch"
        UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let settings = AppSettingsManager(suiteName: suite)
        let auth = ProviderAwareAuthManagerStub(settings: settings, openAIKey: storedKey)
        let switchViewModel = SettingsViewModel(
            authManager: auth,
            verifier: APIKeyVerifierStub(),
            settings: settings
        )
        switchViewModel.selectedProvider = .openAI
        try await Task.sleep(nanoseconds: 100_000_000)

        // Act: уходим на Claude, его медленное чтение ещё в полёте — возвращаемся на OpenAI
        switchViewModel.selectedProvider = .claude
        try await Task.sleep(nanoseconds: 50_000_000)
        switchViewModel.selectedProvider = .openAI
        try await Task.sleep(nanoseconds: 600_000_000)

        // Assert: поздний пустой ответ для Claude не должен затирать ключ OpenAI
        XCTAssertTrue(switchViewModel.isKeyPresent)
        XCTAssertEqual(switchViewModel.maskedApiKey, shortMaskKey(storedKey))
    }

    public func testLoadModels_UsesFetcherAndFallsBackToCatalog() async {
        // Arrange: заглушка загрузчика с фиксированным списком
        final class FetcherStub: ModelListFetching {
            var models: [String] = []
            var shouldThrow = false
            func fetchModels(provider: LLMProvider, apiKey: String?) async throws -> [String] {
                if shouldThrow {
                    throw URLError(.notConnectedToInternet)
                }
                return models
            }
        }
        let fetcher = FetcherStub()
        fetcher.models = ["m-alpha", "m-beta"]
        let suite = "test.craftify.load-models"
        UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let settings = AppSettingsManager(suiteName: suite)
        let modelsViewModel = SettingsViewModel(
            authManager: AuthManagerStub(key: nil),
            verifier: APIKeyVerifierStub(),
            settings: settings,
            modelListFetcher: fetcher
        )
        // Act: успешная загрузка списка
        await modelsViewModel.loadModels()
        XCTAssertEqual(modelsViewModel.availableModels, ["m-alpha", "m-beta"])
        // Act: при ошибке — запасной статический каталог
        fetcher.shouldThrow = true
        await modelsViewModel.loadModels()
        XCTAssertEqual(modelsViewModel.availableModels, LLMModelCatalog.curatedModels(for: modelsViewModel.selectedProvider))
    }

    public func testSaveKey_Valid() async {
        guard let viewModel, let _ = authManager else { XCTFail("nil stub")
            return
        }
        await MainActor.run { viewModel.apiKey = "sk-valid-key-1234567890" }
        await viewModel.saveKey()
        XCTAssertTrue(viewModel.isKeyPresent)
        XCTAssertEqual(viewModel.maskedApiKey, shortMaskKey("sk-valid-key-1234567890"))
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isEditingKey)
    }

    public func testSaveKey_Invalid() async {
        guard let viewModel, let _ = authManager else { XCTFail("viewModel is nil")
            return
        }
        await MainActor.run { viewModel.apiKey = "short" }
        await viewModel.saveKey()
        XCTAssertTrue(viewModel.isKeyPresent)
        XCTAssertNil(viewModel.errorMessage)
    }

    public func testSaveKey_RejectedByProvider() async {
        let rejectingViewModel = SettingsViewModel(
            authManager: AuthManagerStub(key: nil),
            verifier: APIKeyVerifierStub(outcome: .invalid)
        )
        rejectingViewModel.apiKey = "sk-wrong-key-1234567890"
        await rejectingViewModel.saveKey()
        XCTAssertFalse(rejectingViewModel.isKeyPresent)
        XCTAssertNotNil(rejectingViewModel.errorMessage)
    }

    public func testSaveKey_ProviderUnreachableStillSaves() async {
        let offlineViewModel = SettingsViewModel(
            authManager: AuthManagerStub(key: nil),
            verifier: APIKeyVerifierStub(outcome: .unreachable)
        )
        offlineViewModel.apiKey = "sk-valid-key-1234567890"
        await offlineViewModel.saveKey()
        XCTAssertTrue(offlineViewModel.isKeyPresent)
        XCTAssertNil(offlineViewModel.errorMessage)
    }

    public func testDeleteKey() async {
        guard let viewModel, let _ = authManager else { XCTFail("nil stub")
            return
        }
        await MainActor.run { viewModel.apiKey = "sk-valid-key-1234567890" }
        await viewModel.saveKey()
        await viewModel.deleteKey()
        XCTAssertFalse(viewModel.isKeyPresent)
        XCTAssertEqual(viewModel.apiKey, "")
    }

    deinit {}
}
