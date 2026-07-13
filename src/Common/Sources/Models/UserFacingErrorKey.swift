import Foundation

/// Ключи для локализованных пользовательских ошибок
public enum UserFacingErrorKey: String {
    case error = "error"
    case adviceUnknownError = "advice_unknown_error"
    case adviceContactSupport = "advice_contact_support"
    case errorNoOperation = "error_no_operation"
    case adviceCheckConnection = "advice_check_connection"
    case errorNoText = "error_no_text"
    case adviceTryAgainLater = "advice_try_again_later"
    case errorParsing = "error_parsing"
    case errorInvalidApiKey = "error_invalid_api_key"
    case adviceCheckApiKey = "advice_check_api_key"
    case errorNetwork = "error_network"
    case errorProcessing = "error_processing"
    case errorCancelled = "error_cancelled"
    case errorUrlNotSupported = "error_url_not_supported"
    case errorDownloadFailed = "error_download_failed"
    case errorExtractText = "error_extract_text"
    case errorTextTooLong = "error_text_too_long"
    case errorConsentRequired = "error_consent_required"
    case errorApiKeyAccess = "error_api_key_access"
    case errorProcessingManagerUnavailable = "error_processing_manager_unavailable"
    case errorClipboard = "error_clipboard"
    case errorRobotsDisallowed = "error_robots_disallowed"
    case errorApiKeyMissing = "error_api_key_missing"
    case adviceAddApiKeyInApp = "advice_add_api_key_in_app"
    case errorRateLimited = "error_rate_limited"
    case errorTimeout = "error_timeout"
    case adviceOpenAppToConsent = "advice_open_app_to_consent"
    // Добавьте другие ключи по мере необходимости

    /// Локализует ключ по таблице Localizable указанного бандла (rawValue совпадает с ключом локализации).
    public func localized(in bundle: Bundle) -> String {
        bundle.localizedString(forKey: rawValue, value: nil, table: nil)
    }
}
