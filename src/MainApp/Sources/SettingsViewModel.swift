import Foundation
import SwiftUI

/// ViewModel для экрана настроек Craftify: управление API-ключом и согласием пользователя
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
    /// Выбранный язык пользователя (реактивно для Picker)
    @Published public var selectedNativeLanguage: String = AppSettingsManager.shared.nativeLanguage
    /// Selected LLM provider tag
    @Published public var selectedProvider: LLMProvider = AppSettingsManager.shared.llmProvider

    private let authManager: AuthManaging

    /// Инициализация с менеджером
    /// - Parameter authManager: Менеджер API-ключа
    public init(authManager: AuthManaging = AuthManager()) {
        self.authManager = authManager
        Task { await load() }
    }

    /// Загрузка состояния (ключ)
    public func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let key = try await authManager.getAPIKey()
            apiKey = key ?? ""
            maskedApiKey = authManager.maskedAPIKey(key)
            isKeyPresent = (key != nil)
            selectedProvider = AppSettingsManager.shared.llmProvider
        } catch {
            apiKey = ""
            maskedApiKey = authManager.maskedAPIKey(nil)
            isKeyPresent = false
            if let userError = error as? UserFacingError {
                let message: String = switch userError.messageKey {
                case .error: L10n.error
                case .adviceUnknownError: L10n.adviceUnknownError
                case .adviceContactSupport: L10n.adviceContactSupport
                case .errorNoOperation: L10n.errorNoOperation
                case .adviceCheckConnection: L10n.adviceCheckConnection
                case .errorNoText: L10n.errorNoText
                case .adviceTryAgainLater: L10n.adviceTryAgainLater
                case .errorParsing: L10n.errorParsing
                case .errorInvalidApiKey: L10n.errorInvalidApiKey
                case .adviceCheckApiKey: L10n.adviceCheckApiKey
                case .errorNetwork: L10n.errorNetwork
                case .errorProcessing: L10n.errorProcessing
                case .errorCancelled: L10n.errorCancelled
                case .errorUrlNotSupported: L10n.errorUrlNotSupported
                case .errorDownloadFailed: L10n.errorDownloadFailed
                case .errorExtractText: L10n.errorExtractText
                case .errorTextTooLong: L10n.errorTextTooLong
                case .errorConsentRequired: L10n.errorConsentRequired
                case .errorApiKeyAccess: L10n.errorApiKeyAccess
                case .errorProcessingManagerUnavailable: L10n.errorProcessingManagerUnavailable
                case .errorClipboard: L10n.errorClipboard
                case .errorRobotsDisallowed: L10n.errorRobotsDisallowed
                }
                let advice: String = switch userError.adviceKey {
                case .error: L10n.error
                case .adviceUnknownError: L10n.adviceUnknownError
                case .adviceContactSupport: L10n.adviceContactSupport
                case .errorNoOperation: L10n.errorNoOperation
                case .adviceCheckConnection: L10n.adviceCheckConnection
                case .errorNoText: L10n.errorNoText
                case .adviceTryAgainLater: L10n.adviceTryAgainLater
                case .errorParsing: L10n.errorParsing
                case .errorInvalidApiKey: L10n.errorInvalidApiKey
                case .adviceCheckApiKey: L10n.adviceCheckApiKey
                case .errorNetwork: L10n.errorNetwork
                case .errorProcessing: L10n.errorProcessing
                case .errorCancelled: L10n.errorCancelled
                case .errorUrlNotSupported: L10n.errorUrlNotSupported
                case .errorDownloadFailed: L10n.errorDownloadFailed
                case .errorExtractText: L10n.errorExtractText
                case .errorTextTooLong: L10n.errorTextTooLong
                case .errorConsentRequired: L10n.errorConsentRequired
                case .errorApiKeyAccess: L10n.errorApiKeyAccess
                case .errorProcessingManagerUnavailable: L10n.errorProcessingManagerUnavailable
                case .errorClipboard: L10n.errorClipboard
                case .errorRobotsDisallowed: L10n.errorRobotsDisallowed
                }
                errorMessage = "\(message)\n\n\(advice)"
            } else if let localized = error as? LocalizedError, let desc = localized.errorDescription {
                errorMessage = desc
            } else {
                errorMessage = UserFacingError.unknown(underlyingError: error).errorDescription
            }
        }
    }

    public func saveNativeLanguage() {
        let suiteName = "group.dev.korchasa.Craftify"
        let userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
        let lang = selectedNativeLanguage
        NSLog("[SettingsViewModel] [SAVE] nativeLanguage: %@, suite: %@, userDefaults: %@", lang, suiteName, String(describing: userDefaults))
        Thread.callStackSymbols.forEach { NSLog("[SettingsViewModel] [SAVE] callStack: %@", $0) }
        AppSettingsManager.shared.nativeLanguage = lang
        let saved = userDefaults.string(forKey: "CraftifyNativeLanguage") ?? "<nil>"
        NSLog("[SettingsViewModel] [SAVE] After set, value in suite: %@", saved)
    }

    /// Сохранить API-ключ
    public func saveKey() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await authManager.setAPIKey(apiKey)
            maskedApiKey = authManager.maskedAPIKey(apiKey)
            isKeyPresent = true
            errorMessage = nil
        } catch {
            if let userError = error as? UserFacingError {
                let message: String = switch userError.messageKey {
                case .error: L10n.error
                case .adviceUnknownError: L10n.adviceUnknownError
                case .adviceContactSupport: L10n.adviceContactSupport
                case .errorNoOperation: L10n.errorNoOperation
                case .adviceCheckConnection: L10n.adviceCheckConnection
                case .errorNoText: L10n.errorNoText
                case .adviceTryAgainLater: L10n.adviceTryAgainLater
                case .errorParsing: L10n.errorParsing
                case .errorInvalidApiKey: L10n.errorInvalidApiKey
                case .adviceCheckApiKey: L10n.adviceCheckApiKey
                case .errorNetwork: L10n.errorNetwork
                case .errorProcessing: L10n.errorProcessing
                case .errorCancelled: L10n.errorCancelled
                case .errorUrlNotSupported: L10n.errorUrlNotSupported
                case .errorDownloadFailed: L10n.errorDownloadFailed
                case .errorExtractText: L10n.errorExtractText
                case .errorTextTooLong: L10n.errorTextTooLong
                case .errorConsentRequired: L10n.errorConsentRequired
                case .errorApiKeyAccess: L10n.errorApiKeyAccess
                case .errorProcessingManagerUnavailable: L10n.errorProcessingManagerUnavailable
                case .errorClipboard: L10n.errorClipboard
                case .errorRobotsDisallowed: L10n.errorRobotsDisallowed
                }
                let advice: String = switch userError.adviceKey {
                case .error: L10n.error
                case .adviceUnknownError: L10n.adviceUnknownError
                case .adviceContactSupport: L10n.adviceContactSupport
                case .errorNoOperation: L10n.errorNoOperation
                case .adviceCheckConnection: L10n.adviceCheckConnection
                case .errorNoText: L10n.errorNoText
                case .adviceTryAgainLater: L10n.adviceTryAgainLater
                case .errorParsing: L10n.errorParsing
                case .errorInvalidApiKey: L10n.errorInvalidApiKey
                case .adviceCheckApiKey: L10n.adviceCheckApiKey
                case .errorNetwork: L10n.errorNetwork
                case .errorProcessing: L10n.errorProcessing
                case .errorCancelled: L10n.errorCancelled
                case .errorUrlNotSupported: L10n.errorUrlNotSupported
                case .errorDownloadFailed: L10n.errorDownloadFailed
                case .errorExtractText: L10n.errorExtractText
                case .errorTextTooLong: L10n.errorTextTooLong
                case .errorConsentRequired: L10n.errorConsentRequired
                case .errorApiKeyAccess: L10n.errorApiKeyAccess
                case .errorProcessingManagerUnavailable: L10n.errorProcessingManagerUnavailable
                case .errorClipboard: L10n.errorClipboard
                case .errorRobotsDisallowed: L10n.errorRobotsDisallowed
                }
                errorMessage = "\(message)\n\n\(advice)"
            } else if let localized = error as? LocalizedError, let desc = localized.errorDescription {
                errorMessage = desc
            } else {
                errorMessage = UserFacingError.unknown(underlyingError: error).errorDescription
            }
        }
    }

    /// Удалить API-ключ
    public func deleteKey() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await authManager.deleteAPIKey()
            apiKey = ""
            maskedApiKey = authManager.maskedAPIKey(nil)
            isKeyPresent = false
            errorMessage = nil
        } catch {
            if let userError = error as? UserFacingError {
                let message: String = switch userError.messageKey {
                case .error: L10n.error
                case .adviceUnknownError: L10n.adviceUnknownError
                case .adviceContactSupport: L10n.adviceContactSupport
                case .errorNoOperation: L10n.errorNoOperation
                case .adviceCheckConnection: L10n.adviceCheckConnection
                case .errorNoText: L10n.errorNoText
                case .adviceTryAgainLater: L10n.adviceTryAgainLater
                case .errorParsing: L10n.errorParsing
                case .errorInvalidApiKey: L10n.errorInvalidApiKey
                case .adviceCheckApiKey: L10n.adviceCheckApiKey
                case .errorNetwork: L10n.errorNetwork
                case .errorProcessing: L10n.errorProcessing
                case .errorCancelled: L10n.errorCancelled
                case .errorUrlNotSupported: L10n.errorUrlNotSupported
                case .errorDownloadFailed: L10n.errorDownloadFailed
                case .errorExtractText: L10n.errorExtractText
                case .errorTextTooLong: L10n.errorTextTooLong
                case .errorConsentRequired: L10n.errorConsentRequired
                case .errorApiKeyAccess: L10n.errorApiKeyAccess
                case .errorProcessingManagerUnavailable: L10n.errorProcessingManagerUnavailable
                case .errorClipboard: L10n.errorClipboard
                case .errorRobotsDisallowed: L10n.errorRobotsDisallowed
                }
                let advice: String = switch userError.adviceKey {
                case .error: L10n.error
                case .adviceUnknownError: L10n.adviceUnknownError
                case .adviceContactSupport: L10n.adviceContactSupport
                case .errorNoOperation: L10n.errorNoOperation
                case .adviceCheckConnection: L10n.adviceCheckConnection
                case .errorNoText: L10n.errorNoText
                case .adviceTryAgainLater: L10n.adviceTryAgainLater
                case .errorParsing: L10n.errorParsing
                case .errorInvalidApiKey: L10n.errorInvalidApiKey
                case .adviceCheckApiKey: L10n.adviceCheckApiKey
                case .errorNetwork: L10n.errorNetwork
                case .errorProcessing: L10n.errorProcessing
                case .errorCancelled: L10n.errorCancelled
                case .errorUrlNotSupported: L10n.errorUrlNotSupported
                case .errorDownloadFailed: L10n.errorDownloadFailed
                case .errorExtractText: L10n.errorExtractText
                case .errorTextTooLong: L10n.errorTextTooLong
                case .errorConsentRequired: L10n.errorConsentRequired
                case .errorApiKeyAccess: L10n.errorApiKeyAccess
                case .errorProcessingManagerUnavailable: L10n.errorProcessingManagerUnavailable
                case .errorClipboard: L10n.errorClipboard
                case .errorRobotsDisallowed: L10n.errorRobotsDisallowed
                }
                errorMessage = "\(message)\n\n\(advice)"
            } else if let localized = error as? LocalizedError, let desc = localized.errorDescription {
                errorMessage = desc
            } else {
                errorMessage = UserFacingError.unknown(underlyingError: error).errorDescription
            }
        }
    }

    /// Save selected provider to app settings
    public func saveProvider() {
        AppSettingsManager.shared.llmProvider = selectedProvider
    }

    public var supportedLanguages: [SupportedLanguage] {
        SupportedLanguages.all
    }

    deinit {}
}
