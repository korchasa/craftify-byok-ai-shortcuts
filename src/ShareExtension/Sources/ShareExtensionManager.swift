import CraftifyShared
import Foundation

/// Менеджер Share Extension: обработка текста, копирование, согласие, ошибки
public final class ShareExtensionManager {
    private let inventoryManager: InventoryManaging
    private let authManager: AuthManaging
    private let clipboardManager: AnyObject
    private let processingManager: AnyObject
    private let consentManager: ConsentManaging
    private var isCancelled = false
    private static let maxTextLength = 12000

    /// Инициализация менеджера Share Extension
    public init(
        inventoryManager: InventoryManaging,
        authManager: AuthManaging,
        clipboardManager: AnyObject,
        processingManager: AnyObject,
        consentManager: ConsentManaging
    ) {
        self.inventoryManager = inventoryManager
        self.authManager = authManager
        self.clipboardManager = clipboardManager
        self.processingManager = processingManager
        self.consentManager = consentManager
    }

    /// Асинхронная обработка текста и копирование результата
    public func process(text: String, operation: InventoryOperation?) async -> (success: Bool, error: String?)? {
        if isCancelled {
            isCancelled = false
            return (false, "Операция отменена")
        }
        guard !text.isEmpty else {
            return (false, "Нет текста для обработки")
        }
        if text.count > Self.maxTextLength {
            return (false, "Текст слишком длинный для обработки")
        }
        if !consentManager.getConsent() {
            return (false, "Требуется согласие пользователя")
        }
        let apiKey: String?
        do {
            apiKey = try await authManager.getAPIKey()
        } catch {
            return (false, "Ошибка доступа к API-ключу")
        }
        guard let key = apiKey, key.starts(with: "sk-") else {
            return (false, "Неверный API-ключ")
        }
        guard let op = operation else {
            return (false, "Нет операции для обработки")
        }
        // Вызов менеджера обработки
        var processedText = ""
        if let pm = processingManager as? ProcessingManagerStub {
            // Синхронный вызов stub-процесса
            var stubResult: Result<String, Error>?
            pm.process(text: text, operation: op) { res in
                stubResult = res
            }
            guard let result = stubResult else {
                return (false, "Processing error")
            }
            switch result {
            case let .failure(err):
                return (false, err.localizedDescription)
            case let .success(str):
                processedText = str
            }
        } else {
            return (false, "Processing manager unavailable")
        }
        if isCancelled {
            isCancelled = false
            return (false, "Операция отменена")
        }
        // Копирование в буфер обмена
        if let cb = clipboardManager as? ClipboardManagerStub {
            if !cb.copy(text: processedText) {
                return (false, "Ошибка доступа к буферу")
            }
        } else {
            return (false, "Ошибка доступа к буферу")
        }
        return (true, nil)
    }

    /// Устанавливает флаг отмены обработки
    public func cancelProcessing() {
        isCancelled = true
    }

    deinit {}
}
