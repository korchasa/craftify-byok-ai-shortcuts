import Foundation
import os

/// Service for centralized access to application settings (Singleton)
///
/// Use this class to get and set user preferences such as native language.
public final class AppSettingsManager {
    /// Shared singleton instance (always uses App Group)
    public static let shared = AppSettingsManager(suiteName: AppGroup.identifier)
    private let userDefaults: UserDefaults
    private let nativeLanguageKey = "CraftifyNativeLanguage"
    private let llmProviderKey = "CraftifyLLMProvider"
    private let llmModelKeyPrefix = "CraftifyLLMModel."
    private let logManager: LogManagerShared

    /// Initializes the settings manager
    /// - Parameters:
    ///   - suiteName: Optional suite name for UserDefaults (for App Group support)
    ///   - logManager: Optional log manager for logging changes (default: OSLogManagerShared)
    public init(suiteName: String? = nil, logManager: LogManagerShared = OSLogManagerShared(category: "AppSettingsManager")) {
        if let suiteName {
            self.userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
        } else {
            self.userDefaults = .standard
        }
        self.logManager = logManager
    }

    /// Current user's native language
    public var nativeLanguage: String {
        get {
            userDefaults.string(forKey: nativeLanguageKey) ?? Locale.current.language.languageCode?.identifier ?? "en"
        }
        set {
            userDefaults.set(newValue, forKey: nativeLanguageKey)
        }
    }

    /// Currently selected LLM provider.
    public var llmProvider: LLMProvider {
        get {
            if let raw = userDefaults.string(forKey: llmProviderKey), let provider = LLMProvider(rawValue: raw) {
                return provider
            }
            return .openAI // default
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: llmProviderKey)
            logManager.log(LogEntry(
                level: LogLevel.info,
                module: "AppSettingsManager",
                message: "[SET] CraftifyLLMProvider",
                metadata: [
                    "newValue": newValue.rawValue
                ]
            ))
        }
    }

    /// Выбранная модель для провайдера; без сохранённого значения — модель по умолчанию из каталога
    public func model(for provider: LLMProvider) -> String {
        let stored = userDefaults.string(forKey: llmModelKeyPrefix + provider.rawValue)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let stored, !stored.isEmpty {
            return stored
        }
        return LLMModelCatalog.defaultModel(for: provider)
    }

    /// Сохраняет выбранную модель для провайдера
    public func setModel(_ model: String, for provider: LLMProvider) {
        userDefaults.set(model, forKey: llmModelKeyPrefix + provider.rawValue)
        logManager.log(LogEntry(
            level: LogLevel.info,
            module: "AppSettingsManager",
            message: "[SET] CraftifyLLMModel",
            metadata: [
                "provider": provider.rawValue,
                "newValue": model
            ]
        ))
    }

    /// English name for the current user's native language (e.g., "Russian" for "ru").
    public var nativeLanguageEnglishName: String {
        SupportedLanguages.all.first { $0.code == nativeLanguage }?.englishName ?? nativeLanguage
    }

    /// Native (localized) display name for the current user's native language (e.g., "русский язык" for "ru").
    public var nativeLanguageDisplayName: String {
        SupportedLanguages.all.first { $0.code == nativeLanguage }?.name ?? nativeLanguage
    }

    /// Required deinitializer for SwiftLint compliance
    deinit {}
}
