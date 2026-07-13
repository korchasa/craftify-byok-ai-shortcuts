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

    /// Выбранный провайдер; сохраняется сразу при изменении, поле ключа и модель перезагружаются
    @Published public var selectedProvider: LLMProvider {
        didSet {
            guard oldValue != selectedProvider else { return }
            settings.llmProvider = selectedProvider
            isEditingKey = false
            selectedModel = settings.model(for: selectedProvider)
            Task { await load() }
        }
    }

    /// Выбранная модель текущего провайдера; сохраняется сразу при изменении
    @Published public var selectedModel: String {
        didSet {
            guard oldValue != selectedModel else { return }
            settings.setModel(selectedModel, for: selectedProvider)
        }
    }

    /// Проверенный список моделей текущего провайдера
    public var curatedModels: [String] {
        LLMModelCatalog.curatedModels(for: selectedProvider)
    }

    /// Разрешён ли свободный ввод модели для текущего провайдера (OpenRouter)
    public var allowsCustomModel: Bool {
        LLMModelCatalog.allowsCustomModel(selectedProvider)
    }

    private let authManager: AuthManaging
    private let verifier: APIKeyVerifying
    private let settings: AppSettingsManager

    /// Инициализация с менеджерами
    /// - Parameters:
    ///   - authManager: Менеджер API-ключа
    ///   - verifier: Проверка ключа у провайдера
    ///   - settings: Хранилище настроек (App Group)
    public init(
        authManager: AuthManaging = AuthManager(),
        verifier: APIKeyVerifying = APIKeyVerifier(),
        settings: AppSettingsManager = .shared
    ) {
        self.authManager = authManager
        self.verifier = verifier
        self.settings = settings
        self.selectedNativeLanguage = settings.nativeLanguage
        let provider = settings.llmProvider
        self.selectedProvider = provider
        self.selectedModel = settings.model(for: provider)
        Task { await load() }
    }

    /// Загрузка состояния (ключ текущего провайдера).
    /// Реальный ключ никогда не публикуется — наружу уходит только короткая маска.
    public func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let key = try await authManager.getAPIKey()
            apiKey = ""
            maskedApiKey = shortMaskKey(key)
            isKeyPresent = (key != nil)
        } catch {
            apiKey = ""
            maskedApiKey = shortMaskKey(nil)
            isKeyPresent = false
            presentError(error)
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
