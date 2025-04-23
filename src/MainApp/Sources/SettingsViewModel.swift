import CraftifyShared
import Foundation
import SwiftUI

/// ViewModel для экрана настроек Craftify: управление API-ключом и согласием пользователя
@MainActor
public final class SettingsViewModel: ObservableObject {
    /// Введённый пользователем API-ключ
    @Published public var apiKey: String = ""
    /// Маскированный API-ключ для отображения
    @Published public var maskedApiKey: String = ""
    /// Флаг согласия пользователя
    @Published public var consentGiven: Bool = false
    /// Сообщение об ошибке
    @Published public var errorMessage: String? = nil
    /// Индикатор загрузки
    @Published public var isLoading: Bool = false
    /// Признак наличия ключа
    @Published public var isKeyPresent: Bool = false

    private let authManager: AuthManaging
    private let consentManager: ConsentManaging

    /// Инициализация с менеджерами
    /// - Parameters:
    ///   - authManager: Менеджер API-ключа
    ///   - consentManager: Менеджер согласия
    public init(authManager: AuthManaging = AuthManager(), consentManager: ConsentManaging = ConsentManager()) {
        self.authManager = authManager
        self.consentManager = consentManager
        Task { await load() }
    }

    /// Загрузка состояния (ключ, согласие)
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
        consentGiven = consentManager.getConsent()
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

    /// Установить согласие пользователя
    /// - Parameter value: Новое значение согласия
    public func setConsent(_ value: Bool) {
        consentManager.setConsent(value)
        consentGiven = value
    }

    deinit {}
}
