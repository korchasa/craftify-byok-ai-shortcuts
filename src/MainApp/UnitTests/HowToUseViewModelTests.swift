// @testable import Common
import XCTest

@MainActor
public final class HowToUseViewModelTests: XCTestCase {
    /// Заглушка загрузчика списка моделей
    private final class FetcherStub: ModelListFetching {
        var models: [String] = []
        var shouldThrow = false
        func fetchModels(provider: LLMProvider, apiKey: String?) async throws -> [String] {
            if shouldThrow {
                throw URLError(.notConnectedToInternet)
            }
            return models
        }
    }

    private func makeSettings(_ suite: String) -> AppSettingsManager {
        UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
        return AppSettingsManager(suiteName: suite)
    }

    public func testInitialConsentIsFalseByDefault() {
        let stub = ConsentManagerStub()
        let viewModel = HowToUseViewModel(consentManager: stub)
        XCTAssertFalse(viewModel.consentGiven)
    }

    public func testSaveConsentPersistsValue() {
        let stub = ConsentManagerStub()
        let viewModel = HowToUseViewModel(consentManager: stub)
        viewModel.consentGiven = true
        viewModel.saveConsent()
        XCTAssertTrue(stub.getConsent())
    }

    public func testSubmitKey_EmptyKeyDoesNothing() async {
        let suite = "test.craftify.onboarding-empty"
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let consent = ConsentManagerStub()
        let viewModel = HowToUseViewModel(
            consentManager: consent,
            authManager: AuthManagerStub(key: nil),
            verifier: APIKeyVerifierStub(),
            settings: makeSettings(suite),
            modelListFetcher: FetcherStub()
        )
        let done = await viewModel.submitKey()
        XCTAssertFalse(done)
        XCTAssertFalse(viewModel.showModelStep)
        XCTAssertFalse(consent.getConsent())
    }

    public func testSubmitKey_ValidKeySavesKeyAndProviderThenShowsModelStep() async {
        let suite = "test.craftify.onboarding-valid"
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let settings = makeSettings(suite)
        let consent = ConsentManagerStub()
        let authManager = AuthManagerStub(key: nil)
        let fetcher = FetcherStub()
        fetcher.models = ["m-alpha", "m-beta"]
        let viewModel = HowToUseViewModel(
            consentManager: consent,
            authManager: authManager,
            verifier: APIKeyVerifierStub(),
            settings: settings,
            modelListFetcher: fetcher
        )
        viewModel.selectedProvider = .claude
        viewModel.apiKey = "sk-valid-key-1234567890"
        let done = await viewModel.submitKey()
        XCTAssertTrue(done)
        // Провайдер и ключ сохранены, список моделей загружен, шаг выбора открыт
        XCTAssertEqual(settings.llmProvider, .claude)
        let savedKey = try? await authManager.getAPIKey()
        XCTAssertEqual(savedKey, "sk-valid-key-1234567890")
        XCTAssertTrue(viewModel.showModelStep)
        XCTAssertEqual(viewModel.availableModels, ["m-alpha", "m-beta"])
        // Согласие фиксируется только после шага выбора модели
        XCTAssertFalse(consent.getConsent())
    }

    public func testSubmitKey_RejectedKeyBlocksButKeepsProvider() async {
        let suite = "test.craftify.onboarding-rejected"
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let settings = makeSettings(suite)
        let consent = ConsentManagerStub()
        let viewModel = HowToUseViewModel(
            consentManager: consent,
            authManager: AuthManagerStub(key: nil),
            verifier: APIKeyVerifierStub(outcome: .invalid),
            settings: settings,
            modelListFetcher: FetcherStub()
        )
        viewModel.selectedProvider = .mistral
        viewModel.apiKey = "sk-wrong-key-1234567890"
        let done = await viewModel.submitKey()
        XCTAssertFalse(done)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showModelStep)
        XCTAssertFalse(consent.getConsent())
        // Выбор провайдера не теряется даже при отклонённом ключе
        XCTAssertEqual(settings.llmProvider, .mistral)
    }

    public func testFinishOnboarding_PersistsModelAndConsent() async {
        let suite = "test.craftify.onboarding-finish"
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let settings = makeSettings(suite)
        let consent = ConsentManagerStub()
        let fetcher = FetcherStub()
        fetcher.models = ["m-alpha", "m-beta"]
        let viewModel = HowToUseViewModel(
            consentManager: consent,
            authManager: AuthManagerStub(key: nil),
            verifier: APIKeyVerifierStub(),
            settings: settings,
            modelListFetcher: fetcher
        )
        viewModel.selectedProvider = .openAI
        viewModel.apiKey = "sk-valid-key-1234567890"
        _ = await viewModel.submitKey()
        viewModel.selectedModel = "m-beta"
        viewModel.finishOnboarding()
        XCTAssertEqual(settings.model(for: .openAI), "m-beta")
        XCTAssertTrue(consent.getConsent())
        XCTAssertFalse(viewModel.showModelStep)
    }

    public func testSkipKeySetup_PersistsProviderAndConsentWithoutKey() async {
        let suite = "test.craftify.onboarding-skip"
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let settings = makeSettings(suite)
        let consent = ConsentManagerStub()
        let authManager = AuthManagerStub(key: nil)
        let viewModel = HowToUseViewModel(
            consentManager: consent,
            authManager: authManager,
            verifier: APIKeyVerifierStub(),
            settings: settings,
            modelListFetcher: FetcherStub()
        )
        viewModel.selectedProvider = .openRouter
        viewModel.skipKeySetup()
        XCTAssertTrue(consent.getConsent())
        XCTAssertEqual(settings.llmProvider, .openRouter)
        let savedKey = try? await authManager.getAPIKey()
        XCTAssertNil(savedKey)
    }

    public func testLoadModels_FailureReportsFlagAndKeepsGoing() async {
        let suite = "test.craftify.onboarding-load-fail"
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let consent = ConsentManagerStub()
        let fetcher = FetcherStub()
        fetcher.shouldThrow = true
        let viewModel = HowToUseViewModel(
            consentManager: consent,
            authManager: AuthManagerStub(key: nil),
            verifier: APIKeyVerifierStub(),
            settings: makeSettings(suite),
            modelListFetcher: fetcher
        )
        viewModel.apiKey = "sk-valid-key-1234567890"
        let done = await viewModel.submitKey()
        // Сбой загрузки списка не блокирует онбординг: шаг открыт, дефолтная модель остаётся
        XCTAssertTrue(done)
        XCTAssertTrue(viewModel.showModelStep)
        XCTAssertTrue(viewModel.modelsLoadFailed)
        XCTAssertEqual(viewModel.availableModels, [])
        XCTAssertFalse(viewModel.selectedModel.isEmpty)
    }

    deinit {}
}
