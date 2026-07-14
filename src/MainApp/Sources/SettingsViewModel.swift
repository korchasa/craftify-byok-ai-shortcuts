import Foundation
import SwiftUI

/// ViewModel для экрана настроек Craftify: управление API-ключом и согласием пользователя
@preconcurrency
@MainActor
public final class SettingsViewModel: ObservableObject {
    /// Введённый пользователем API-ключ
    @Published public var apiKey: String = ""
    /// Маскированный API-ключ для отображения
    @Published public var maskedApiKey: String = ""
    /// Сообщение об ошибке
    @Published public var errorMessage: String? = nil
    /// Индикатор загрузки
    @Published public var isLoading: Bool = false
    /// Признак наличия ключа
    @Published public var isKeyPresent: Bool = false
    /// Идёт ввод нового ключа (поле всегда начинается пустым — сохранённый ключ не раскрывается)
    @Published public var isEditingKey: Bool = false
    /// Выбранный язык пользователя; сохраняется сразу при изменении
    @Published public var selectedNativeLanguage: String {
        didSet {
            guard oldValue != selectedNativeLanguage else { return }
            settings.nativeLanguage = selectedNativeLanguage
        }
    }

    /// Выбранный провайдер; сохраняется сразу при изменении, поле ключа и модели перезагружаются
    @Published public var selectedProvider: LLMProvider {
        didSet {
            guard oldValue != selectedProvider else { return }
            settings.llmProvider = selectedProvider
            isEditingKey = false
            selectedModel = settings.model(for: selectedProvider)
            availableModels = []
            Task {
                await load()
                await loadModels()
            }
        }
    }

    /// Выбранная модель текущего провайдера; сохраняется сразу при изменении
    @Published public var selectedModel: String {
        didSet {
            guard oldValue != selectedModel else { return }
            settings.setModel(selectedModel, for: selectedProvider)
        }
    }

    /// Загруженный с API список моделей текущего провайдера
    @Published public private(set) var availableModels: [String] = []
    /// Идёт загрузка списка моделей
    @Published public private(set) var isLoadingModels: Bool = false
    /// Последняя загрузка списка моделей не удалась
    @Published public private(set) var modelsLoadFailed: Bool = false

    private let authManager: AuthManaging
    private let verifier: APIKeyVerifying
    private let settings: AppSettingsManager
    private let modelListFetcher: ModelListFetching

    /// Инициализация с менеджерами
    /// - Parameters:
    ///   - authManager: Менеджер API-ключа
    ///   - verifier: Проверка ключа у провайдера
    ///   - settings: Хранилище настроек (App Group)
    ///   - modelListFetcher: Загрузчик списка моделей провайдера
    public init(
        authManager: AuthManaging = AuthManager(),
        verifier: APIKeyVerifying = APIKeyVerifier(),
        settings: AppSettingsManager = .shared,
        modelListFetcher: ModelListFetching = LLMModelListFetcher()
    ) {
        self.authManager = authManager
        self.verifier = verifier
        self.settings = settings
        self.modelListFetcher = modelListFetcher
        self.selectedNativeLanguage = settings.nativeLanguage
        let provider = settings.llmProvider
        self.selectedProvider = provider
        self.selectedModel = settings.model(for: provider)
        Task {
            await load()
            await loadModels()
        }
    }

    /// Загрузка состояния (ключ текущего провайдера).
    /// Реальный ключ никогда не публикуется — наружу уходит только короткая маска.
    public func load() async {
        // Поздний ответ для уже смененного провайдера отбрасываем,
        // чтобы он не затирал ключ текущего провайдера
        let provider = selectedProvider
        isLoading = true
        defer { isLoading = false }
        do {
            let key = try await authManager.getAPIKey()
            guard provider == selectedProvider else { return }
            apiKey = ""
            maskedApiKey = shortMaskKey(key)
            isKeyPresent = (key != nil)
        } catch {
            guard provider == selectedProvider else { return }
            apiKey = ""
            maskedApiKey = shortMaskKey(nil)
            isKeyPresent = false
            presentError(error)
        }
    }

    /// Загружает список моделей текущего провайдера с его API
    public func loadModels() async {
        let provider = selectedProvider
        isLoadingModels = true
        defer { isLoadingModels = false }
        let key = try? await authManager.getAPIKey()
        do {
            let models = try await modelListFetcher.fetchModels(provider: provider, apiKey: key)
            // Поздний ответ для уже смененного провайдера отбрасываем
            guard provider == selectedProvider else { return }
            availableModels = models
            modelsLoadFailed = false
        } catch {
            guard provider == selectedProvider else { return }
            availableModels = []
            modelsLoadFailed = true
        }
    }

    /// Начать ввод нового ключа: поле всегда пустое
    public func beginEditing() {
        apiKey = ""
        errorMessage = nil
        isEditingKey = true
    }

    /// Отменить ввод и вернуться к маскированному отображению
    public func cancelEditing() {
        apiKey = ""
        errorMessage = nil
        isEditingKey = false
    }

    /// Проверить ключ у провайдера и сохранить
    public func saveKey() async {
        isLoading = true
        defer { isLoading = false }
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if await verifier.verify(key: key, provider: selectedProvider) == .invalid {
            errorMessage = "\(localized(.errorInvalidApiKey))\n\n\(localized(.adviceCheckApiKey))"
            return
        }
        do {
            try await authManager.setAPIKey(key)
            apiKey = ""
            maskedApiKey = shortMaskKey(key)
            isKeyPresent = true
            isEditingKey = false
            errorMessage = nil
        } catch {
            presentError(error)
        }
    }

    /// Удалить API-ключ
    public func deleteKey() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await authManager.deleteAPIKey()
            apiKey = ""
            maskedApiKey = shortMaskKey(nil)
            isKeyPresent = false
            isEditingKey = false
            errorMessage = nil
        } catch {
            presentError(error)
        }
    }

    public var supportedLanguages: [SupportedLanguage] {
        SupportedLanguages.all
    }

    /// Локализует ключ ошибки по таблице Localizable бандла приложения
    private func localized(_ key: UserFacingErrorKey) -> String {
        key.localized(in: Bundle(for: SettingsViewModel.self))
    }

    private func presentError(_ error: Error) {
        if let userError = error as? UserFacingError {
            errorMessage = "\(localized(userError.messageKey))\n\n\(localized(userError.adviceKey))"
        } else if error is AuthManagerError {
            errorMessage = "\(localized(.errorApiKeyAccess))\n\n\(localized(.adviceCheckApiKey))"
        } else if let localizedError = error as? LocalizedError, let desc = localizedError.errorDescription {
            errorMessage = desc
        } else {
            let unknown = UserFacingError.unknown(underlyingError: error)
            errorMessage = "\(localized(unknown.messageKey))\n\n\(localized(unknown.adviceKey))"
        }
    }

    deinit {}
}
