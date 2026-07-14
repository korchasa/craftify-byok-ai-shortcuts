import Foundation
import SwiftUI

/// ViewModel для HowToUseView: согласие пользователя и первичная настройка
/// «провайдер + ключ + модель» за один заход
@preconcurrency
@MainActor
public final class HowToUseViewModel: ObservableObject {
    @Published public var consentGiven: Bool
    /// Введённый пользователем API-ключ (обязателен для полного онбординга;
    /// без ключа доступен только путь «настроить позже»)
    @Published public var apiKey: String = ""
    /// Выбранный провайдер
    @Published public var selectedProvider: LLMProvider {
        didSet {
            guard oldValue != selectedProvider else { return }
            selectedModel = settings.model(for: selectedProvider)
        }
    }

    /// Идёт проверка ключа у провайдера
    @Published public var isVerifying: Bool = false
    /// Сообщение об ошибке проверки ключа
    @Published public var errorMessage: String? = nil
    /// Модель для выбранного провайдера; предзаполняется значением по умолчанию
    @Published public var selectedModel: String
    /// Открыт шаг выбора модели (после успешной проверки ключа)
    @Published public var showModelStep: Bool = false
    /// Загруженный с API список моделей текущего провайдера
    @Published public private(set) var availableModels: [String] = []
    /// Идёт загрузка списка моделей
    @Published public private(set) var isLoadingModels: Bool = false
    /// Последняя загрузка списка моделей не удалась
    @Published public private(set) var modelsLoadFailed: Bool = false

    private let consentManager: ConsentManaging
    private let authManager: AuthManaging
    private let verifier: APIKeyVerifying
    private let settings: AppSettingsManager
    private let modelListFetcher: ModelListFetching

    /// Инициализация с менеджерами
    /// - Parameters:
    ///   - consentManager: Менеджер согласия
    ///   - authManager: Менеджер API-ключа
    ///   - verifier: Проверка ключа у провайдера
    ///   - settings: Хранилище настроек (App Group)
    ///   - modelListFetcher: Загрузчик списка моделей провайдера
    public init(
        consentManager: ConsentManaging,
        authManager: AuthManaging = AuthManager(),
        verifier: APIKeyVerifying = APIKeyVerifier(),
        settings: AppSettingsManager = .shared,
        modelListFetcher: ModelListFetching = LLMModelListFetcher()
    ) {
        self.consentManager = consentManager
        self.authManager = authManager
        self.verifier = verifier
        self.settings = settings
        self.modelListFetcher = modelListFetcher
        self.consentGiven = consentManager.getConsent()
        let provider = settings.llmProvider
        self.selectedProvider = provider
        self.selectedModel = settings.model(for: provider)
    }

    /// Сохраняет согласие пользователя
    public func saveConsent() {
        consentManager.setConsent(consentGiven)
    }

    /// Шаг 1: проверяет и сохраняет ключ, загружает список моделей и открывает шаг выбора.
    /// Выбор провайдера сохраняется в любом случае — даже при отклонённом ключе.
    /// Возвращает false, если ключ пуст или провайдер его отклонил.
    public func submitKey() async -> Bool {
        errorMessage = nil
        settings.llmProvider = selectedProvider
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return false }
        isVerifying = true
        defer { isVerifying = false }
        if await verifier.verify(key: key, provider: selectedProvider) == .invalid {
            errorMessage = "\(localized(.errorInvalidApiKey))\n\n\(localized(.adviceCheckApiKey))"
            return false
        }
        try? await authManager.setAPIKey(key)
        selectedModel = settings.model(for: selectedProvider)
        showModelStep = true
        await loadModels()
        return true
    }

    /// Загружает список моделей текущего провайдера с его API
    public func loadModels() async {
        let provider = selectedProvider
        isLoadingModels = true
        defer { isLoadingModels = false }
        let key = try? await authManager.getAPIKey()
        do {
            let models = try await modelListFetcher.fetchModels(provider: provider, apiKey: key)
            guard provider == selectedProvider else { return }
            availableModels = models
            modelsLoadFailed = false
        } catch {
            guard provider == selectedProvider else { return }
            availableModels = []
            modelsLoadFailed = true
        }
    }

    /// Шаг 2: фиксирует выбранную модель и согласие, закрывает онбординг
    public func finishOnboarding() {
        settings.setModel(selectedModel, for: selectedProvider)
        showModelStep = false
        consentGiven = true
        saveConsent()
    }

    /// Путь «настроить позже»: согласие без ключа; провайдер сохраняется
    public func skipKeySetup() {
        settings.llmProvider = selectedProvider
        consentGiven = true
        saveConsent()
    }

    /// Локализует ключ ошибки по таблице Localizable бандла приложения
    private func localized(_ key: UserFacingErrorKey) -> String {
        key.localized(in: Bundle(for: HowToUseViewModel.self))
    }

    deinit {
        // Очистка ресурсов не требуется
    }
}
