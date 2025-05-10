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
        } catch {
            apiKey = ""
            maskedApiKey = authManager.maskedAPIKey(nil)
            isKeyPresent = false
            if let userError = error as? UserFacingError {
                let message: String = switch userError.messageKey {
                case .error: NSLocalizedString("error", bundle: .main, comment: "")
                case .adviceUnknownError: NSLocalizedString("advice_unknown_error", bundle: .main, comment: "")
                case .adviceContactSupport: NSLocalizedString("advice_contact_support", bundle: .main, comment: "")
                case .errorNoOperation: NSLocalizedString("error_no_operation", bundle: .main, comment: "")
                case .adviceCheckConnection: NSLocalizedString("advice_check_connection", bundle: .main, comment: "")
                case .errorNoText: NSLocalizedString("error_no_text", bundle: .main, comment: "")
                case .adviceTryAgainLater: NSLocalizedString("advice_try_again_later", bundle: .main, comment: "")
                case .errorParsing: NSLocalizedString("error_parsing", bundle: .main, comment: "")
                case .errorInvalidApiKey: NSLocalizedString("error_invalid_api_key", bundle: .main, comment: "")
                case .adviceCheckApiKey: NSLocalizedString("advice_check_api_key", bundle: .main, comment: "")
                case .errorNetwork: NSLocalizedString("error_network", bundle: .main, comment: "")
                case .errorProcessing: NSLocalizedString("error_processing", bundle: .main, comment: "")
                case .errorCancelled: NSLocalizedString("error_cancelled", bundle: .main, comment: "")
                case .errorUrlNotSupported: NSLocalizedString("error_url_not_supported", bundle: .main, comment: "")
                case .errorDownloadFailed: NSLocalizedString("error_download_failed", bundle: .main, comment: "")
                case .errorExtractText: NSLocalizedString("error_extract_text", bundle: .main, comment: "")
                case .errorTextTooLong: NSLocalizedString("error_text_too_long", bundle: .main, comment: "")
                case .errorConsentRequired: NSLocalizedString("error_consent_required", bundle: .main, comment: "")
                case .errorApiKeyAccess: NSLocalizedString("error_api_key_access", bundle: .main, comment: "")
                case .errorProcessingManagerUnavailable: NSLocalizedString("error_processing_manager_unavailable", bundle: .main, comment: "")
                case .errorClipboard: NSLocalizedString("error_clipboard", bundle: .main, comment: "")
                }
                let advice: String = switch userError.adviceKey {
                case .error: NSLocalizedString("error", bundle: .main, comment: "")
                case .adviceUnknownError: NSLocalizedString("advice_unknown_error", bundle: .main, comment: "")
                case .adviceContactSupport: NSLocalizedString("advice_contact_support", bundle: .main, comment: "")
                case .errorNoOperation: NSLocalizedString("error_no_operation", bundle: .main, comment: "")
                case .adviceCheckConnection: NSLocalizedString("advice_check_connection", bundle: .main, comment: "")
                case .errorNoText: NSLocalizedString("error_no_text", bundle: .main, comment: "")
                case .adviceTryAgainLater: NSLocalizedString("advice_try_again_later", bundle: .main, comment: "")
                case .errorParsing: NSLocalizedString("error_parsing", bundle: .main, comment: "")
                case .errorInvalidApiKey: NSLocalizedString("error_invalid_api_key", bundle: .main, comment: "")
                case .adviceCheckApiKey: NSLocalizedString("advice_check_api_key", bundle: .main, comment: "")
                case .errorNetwork: NSLocalizedString("error_network", bundle: .main, comment: "")
                case .errorProcessing: NSLocalizedString("error_processing", bundle: .main, comment: "")
                case .errorCancelled: NSLocalizedString("error_cancelled", bundle: .main, comment: "")
                case .errorUrlNotSupported: NSLocalizedString("error_url_not_supported", bundle: .main, comment: "")
                case .errorDownloadFailed: NSLocalizedString("error_download_failed", bundle: .main, comment: "")
                case .errorExtractText: NSLocalizedString("error_extract_text", bundle: .main, comment: "")
                case .errorTextTooLong: NSLocalizedString("error_text_too_long", bundle: .main, comment: "")
                case .errorConsentRequired: NSLocalizedString("error_consent_required", bundle: .main, comment: "")
                case .errorApiKeyAccess: NSLocalizedString("error_api_key_access", bundle: .main, comment: "")
                case .errorProcessingManagerUnavailable: NSLocalizedString("error_processing_manager_unavailable", bundle: .main, comment: "")
                case .errorClipboard: NSLocalizedString("error_clipboard", bundle: .main, comment: "")
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
                case .error: NSLocalizedString("error", bundle: .main, comment: "")
                case .adviceUnknownError: NSLocalizedString("advice_unknown_error", bundle: .main, comment: "")
                case .adviceContactSupport: NSLocalizedString("advice_contact_support", bundle: .main, comment: "")
                case .errorNoOperation: NSLocalizedString("error_no_operation", bundle: .main, comment: "")
                case .adviceCheckConnection: NSLocalizedString("advice_check_connection", bundle: .main, comment: "")
                case .errorNoText: NSLocalizedString("error_no_text", bundle: .main, comment: "")
                case .adviceTryAgainLater: NSLocalizedString("advice_try_again_later", bundle: .main, comment: "")
                case .errorParsing: NSLocalizedString("error_parsing", bundle: .main, comment: "")
                case .errorInvalidApiKey: NSLocalizedString("error_invalid_api_key", bundle: .main, comment: "")
                case .adviceCheckApiKey: NSLocalizedString("advice_check_api_key", bundle: .main, comment: "")
                case .errorNetwork: NSLocalizedString("error_network", bundle: .main, comment: "")
                case .errorProcessing: NSLocalizedString("error_processing", bundle: .main, comment: "")
                case .errorCancelled: NSLocalizedString("error_cancelled", bundle: .main, comment: "")
                case .errorUrlNotSupported: NSLocalizedString("error_url_not_supported", bundle: .main, comment: "")
                case .errorDownloadFailed: NSLocalizedString("error_download_failed", bundle: .main, comment: "")
                case .errorExtractText: NSLocalizedString("error_extract_text", bundle: .main, comment: "")
                case .errorTextTooLong: NSLocalizedString("error_text_too_long", bundle: .main, comment: "")
                case .errorConsentRequired: NSLocalizedString("error_consent_required", bundle: .main, comment: "")
                case .errorApiKeyAccess: NSLocalizedString("error_api_key_access", bundle: .main, comment: "")
                case .errorProcessingManagerUnavailable: NSLocalizedString("error_processing_manager_unavailable", bundle: .main, comment: "")
                case .errorClipboard: NSLocalizedString("error_clipboard", bundle: .main, comment: "")
                }
                let advice: String = switch userError.adviceKey {
                case .error: NSLocalizedString("error", bundle: .main, comment: "")
                case .adviceUnknownError: NSLocalizedString("advice_unknown_error", bundle: .main, comment: "")
                case .adviceContactSupport: NSLocalizedString("advice_contact_support", bundle: .main, comment: "")
                case .errorNoOperation: NSLocalizedString("error_no_operation", bundle: .main, comment: "")
                case .adviceCheckConnection: NSLocalizedString("advice_check_connection", bundle: .main, comment: "")
                case .errorNoText: NSLocalizedString("error_no_text", bundle: .main, comment: "")
                case .adviceTryAgainLater: NSLocalizedString("advice_try_again_later", bundle: .main, comment: "")
                case .errorParsing: NSLocalizedString("error_parsing", bundle: .main, comment: "")
                case .errorInvalidApiKey: NSLocalizedString("error_invalid_api_key", bundle: .main, comment: "")
                case .adviceCheckApiKey: NSLocalizedString("advice_check_api_key", bundle: .main, comment: "")
                case .errorNetwork: NSLocalizedString("error_network", bundle: .main, comment: "")
                case .errorProcessing: NSLocalizedString("error_processing", bundle: .main, comment: "")
                case .errorCancelled: NSLocalizedString("error_cancelled", bundle: .main, comment: "")
                case .errorUrlNotSupported: NSLocalizedString("error_url_not_supported", bundle: .main, comment: "")
                case .errorDownloadFailed: NSLocalizedString("error_download_failed", bundle: .main, comment: "")
                case .errorExtractText: NSLocalizedString("error_extract_text", bundle: .main, comment: "")
                case .errorTextTooLong: NSLocalizedString("error_text_too_long", bundle: .main, comment: "")
                case .errorConsentRequired: NSLocalizedString("error_consent_required", bundle: .main, comment: "")
                case .errorApiKeyAccess: NSLocalizedString("error_api_key_access", bundle: .main, comment: "")
                case .errorProcessingManagerUnavailable: NSLocalizedString("error_processing_manager_unavailable", bundle: .main, comment: "")
                case .errorClipboard: NSLocalizedString("error_clipboard", bundle: .main, comment: "")
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
                case .error: NSLocalizedString("error", bundle: .main, comment: "")
                case .adviceUnknownError: NSLocalizedString("advice_unknown_error", bundle: .main, comment: "")
                case .adviceContactSupport: NSLocalizedString("advice_contact_support", bundle: .main, comment: "")
                case .errorNoOperation: NSLocalizedString("error_no_operation", bundle: .main, comment: "")
                case .adviceCheckConnection: NSLocalizedString("advice_check_connection", bundle: .main, comment: "")
                case .errorNoText: NSLocalizedString("error_no_text", bundle: .main, comment: "")
                case .adviceTryAgainLater: NSLocalizedString("advice_try_again_later", bundle: .main, comment: "")
                case .errorParsing: NSLocalizedString("error_parsing", bundle: .main, comment: "")
                case .errorInvalidApiKey: NSLocalizedString("error_invalid_api_key", bundle: .main, comment: "")
                case .adviceCheckApiKey: NSLocalizedString("advice_check_api_key", bundle: .main, comment: "")
                case .errorNetwork: NSLocalizedString("error_network", bundle: .main, comment: "")
                case .errorProcessing: NSLocalizedString("error_processing", bundle: .main, comment: "")
                case .errorCancelled: NSLocalizedString("error_cancelled", bundle: .main, comment: "")
                case .errorUrlNotSupported: NSLocalizedString("error_url_not_supported", bundle: .main, comment: "")
                case .errorDownloadFailed: NSLocalizedString("error_download_failed", bundle: .main, comment: "")
                case .errorExtractText: NSLocalizedString("error_extract_text", bundle: .main, comment: "")
                case .errorTextTooLong: NSLocalizedString("error_text_too_long", bundle: .main, comment: "")
                case .errorConsentRequired: NSLocalizedString("error_consent_required", bundle: .main, comment: "")
                case .errorApiKeyAccess: NSLocalizedString("error_api_key_access", bundle: .main, comment: "")
                case .errorProcessingManagerUnavailable: NSLocalizedString("error_processing_manager_unavailable", bundle: .main, comment: "")
                case .errorClipboard: NSLocalizedString("error_clipboard", bundle: .main, comment: "")
                }
                let advice: String = switch userError.adviceKey {
                case .error: NSLocalizedString("error", bundle: .main, comment: "")
                case .adviceUnknownError: NSLocalizedString("advice_unknown_error", bundle: .main, comment: "")
                case .adviceContactSupport: NSLocalizedString("advice_contact_support", bundle: .main, comment: "")
                case .errorNoOperation: NSLocalizedString("error_no_operation", bundle: .main, comment: "")
                case .adviceCheckConnection: NSLocalizedString("advice_check_connection", bundle: .main, comment: "")
                case .errorNoText: NSLocalizedString("error_no_text", bundle: .main, comment: "")
                case .adviceTryAgainLater: NSLocalizedString("advice_try_again_later", bundle: .main, comment: "")
                case .errorParsing: NSLocalizedString("error_parsing", bundle: .main, comment: "")
                case .errorInvalidApiKey: NSLocalizedString("error_invalid_api_key", bundle: .main, comment: "")
                case .adviceCheckApiKey: NSLocalizedString("advice_check_api_key", bundle: .main, comment: "")
                case .errorNetwork: NSLocalizedString("error_network", bundle: .main, comment: "")
                case .errorProcessing: NSLocalizedString("error_processing", bundle: .main, comment: "")
                case .errorCancelled: NSLocalizedString("error_cancelled", bundle: .main, comment: "")
                case .errorUrlNotSupported: NSLocalizedString("error_url_not_supported", bundle: .main, comment: "")
                case .errorDownloadFailed: NSLocalizedString("error_download_failed", bundle: .main, comment: "")
                case .errorExtractText: NSLocalizedString("error_extract_text", bundle: .main, comment: "")
                case .errorTextTooLong: NSLocalizedString("error_text_too_long", bundle: .main, comment: "")
                case .errorConsentRequired: NSLocalizedString("error_consent_required", bundle: .main, comment: "")
                case .errorApiKeyAccess: NSLocalizedString("error_api_key_access", bundle: .main, comment: "")
                case .errorProcessingManagerUnavailable: NSLocalizedString("error_processing_manager_unavailable", bundle: .main, comment: "")
                case .errorClipboard: NSLocalizedString("error_clipboard", bundle: .main, comment: "")
                }
                errorMessage = "\(message)\n\n\(advice)"
            } else if let localized = error as? LocalizedError, let desc = localized.errorDescription {
                errorMessage = desc
            } else {
                errorMessage = UserFacingError.unknown(underlyingError: error).errorDescription
            }
        }
    }

    public var supportedLanguages: [SupportedLanguage] {
        SupportedLanguages.all
    }

    deinit {}
}
