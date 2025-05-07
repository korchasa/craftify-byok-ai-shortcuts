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
            errorMessage = error.localizedDescription
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
            errorMessage = error.localizedDescription
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
            errorMessage = error.localizedDescription
        }
    }

    public var supportedLanguages: [SupportedLanguage] {
        SupportedLanguages.all
    }

    deinit {}
}
