import Common
import Foundation

/// Менеджер Share Extension: обработка текста, копирование, согласие, ошибки
public final class ShareExtensionManager {
    /// Менеджер операций (inventory), используемый для получения и управления списком доступных операций обработки текста
    public let inventoryManager: InventoryManaging
    private let authManager: AuthManaging
    private let clipboardManager: AnyObject
    private let processingManager: AnyObject
    private let consentManager: ConsentManaging
    /// Менеджер логирования для Share Extension (используется для отладочных и бизнес-логов)
    public let logManager: LogManagerShared
    private var isCancelled = false
    /// Последний результат обработки, используется для режима отображения
    public private(set) var lastResult: String?
    /// Тип последней выполненной операции
    public private(set) var lastOperationKind: OperationKind?
    /// Максимальная длина входного текста для обработки (используется для валидации)
    public static let maxTextLength = 20000
    /// Входной текст для обработки (устанавливается из UI)
    public var inputText: String = ""
    private enum Constants {
        static let resultPreviewLength = 128
    }

    /// Инициализация менеджера Share Extension
    /// - Parameters:
    ///   - inventoryManager: менеджер операций
    ///   - authManager: менеджер API-ключа
    ///   - clipboardManager: менеджер буфера обмена
    ///   - processingManager: менеджер обработки текста
    ///   - consentManager: менеджер согласия пользователя
    ///   - logManager: менеджер логирования
    public init(
        inventoryManager: InventoryManaging,
        authManager: AuthManaging,
        clipboardManager: AnyObject,
        processingManager: AnyObject,
        consentManager: ConsentManaging,
        logManager: LogManagerShared
    ) {
        self.inventoryManager = inventoryManager
        self.authManager = authManager
        self.clipboardManager = clipboardManager
        self.processingManager = processingManager
        self.consentManager = consentManager
        self.logManager = logManager
        self.inputText = ""
    }

    /// Запускает обработку текста с выбранной операцией. Результат копируется в буфер обмена, ошибки отображаются пользователю.
    /// - Parameters:
    ///   - text: Исходный текст для обработки.
    ///   - operation: Операция из inventory (InventoryOperation?).
    /// - Returns: Кортеж (успех: Bool, ошибка: String?) или nil, если операция не выполнена.
    public func process(text: String, operation: InventoryOperation?) async -> (success: Bool, error: String?)? {
        if isCancelled {
            isCancelled = false
            logManager.log(LogEntry(level: .info, module: "ShareExtension", message: "Operation cancelled", metadata: [:]))
            return (false, L10n.errorCancelled)
        }
        guard !text.isEmpty else {
            logManager.log(LogEntry(level: .warning, module: "ShareExtension", message: "No text to process", metadata: [:]))
            return (false, L10n.errorNoText)
        }
        if text.count > Self.maxTextLength {
            logManager.log(LogEntry(level: .warning, module: "ShareExtension", message: "Text too long to process", metadata: ["length": "\(text.count)"]))
            return (false, L10n.errorTextTooLong)
        }
        if !consentManager.getConsent() {
            logManager.log(LogEntry(level: .warning, module: "ShareExtension", message: "User consent required", metadata: [:]))
            return (false, L10n.errorConsentRequired)
        }
        let apiKey: String?
        do {
            apiKey = try await authManager.getAPIKey()
        } catch {
            logManager.log(LogEntry(level: .error, module: "ShareExtension", message: "API key access error", metadata: ["error": "\(error)"]))
            return (false, L10n.errorApiKeyAccess)
        }
        guard let key = apiKey, key.starts(with: "sk-") else {
            logManager.log(LogEntry(level: .error, module: "ShareExtension", message: "Invalid API key", metadata: ["key": authManager.maskedAPIKey(apiKey)]))
            return (false, L10n.errorInvalidApiKey)
        }
        guard let op = operation else {
            logManager.log(LogEntry(level: .error, module: "ShareExtension", message: "No operation to process", metadata: [:]))
            return (false, L10n.errorNoOperation)
        }
        self.lastOperationKind = op.operation
        logManager.log(LogEntry(level: .info, module: "ShareExtension", message: "Start processing", metadata: ["operation": "\(op.operation)"]))
        // Вызов менеджера обработки
        var processedText = ""
        if let pm = processingManager as? ProcessingManagerStub {
            // Синхронный вызов stub-процесса
            var stubResult: Result<String, Error>?
            pm.process(text: text, operation: op) { res in
                stubResult = res
            }
            guard let result = stubResult else {
                logManager.log(LogEntry(level: .error, module: "ShareExtension", message: "Processing error", metadata: [:]))
                return (false, L10n.errorProcessing)
            }
            switch result {
            case let .failure(err):
                logManager.log(LogEntry(level: .error, module: "ShareExtension", message: "Processing error", metadata: ["error": err.localizedDescription]))
                return (false, err.localizedDescription)
            case let .success(str):
                processedText = str
            }
        } else if let pm = processingManager as? ProcessingManaging {
            // Асинхронная обработка через continuation
            do {
                processedText = try await processAsync(pm: pm, text: text, operation: op)
            } catch {
                logManager.log(LogEntry(level: .error, module: "ShareExtension", message: "Processing error", metadata: ["error": error.localizedDescription]))
                return (false, error.localizedDescription)
            }
        } else {
            logManager.log(LogEntry(level: .error, module: "ShareExtension", message: "Processing manager unavailable", metadata: [:]))
            return (false, L10n.errorProcessingManagerUnavailable)
        }
        if isCancelled {
            isCancelled = false
            logManager.log(LogEntry(level: .info, module: "ShareExtension", message: "Operation cancelled", metadata: [:]))
            return (false, L10n.errorCancelled)
        }
        // Настройка режима обработки результата и сохранение результата
        let mode = OperationFactory.make(kind: op.operation).resultMode
        self.lastResult = processedText
        if mode == .display {
            logManager.log(LogEntry(level: .info, module: "ShareExtension", message: "Result mode: display result", metadata: [:]))
            return (true, nil)
        }
        // Копирование в буфер обмена
        if let cb = clipboardManager as? ClipboardManagerStub {
            if !cb.copy(text: processedText) {
                logManager.log(LogEntry(level: .error, module: "ShareExtension", message: "Clipboard access error", metadata: [:]))
                return (false, L10n.errorClipboard)
            }
        } else if let cb = clipboardManager as? ClipboardManaging {
            if !cb.copy(text: processedText) {
                logManager.log(LogEntry(level: .error, module: "ShareExtension", message: "Clipboard access error", metadata: [:]))
                return (false, L10n.errorClipboard)
            }
        } else {
            logManager.log(LogEntry(level: .error, module: "ShareExtension", message: "Clipboard access error (type)", metadata: [:]))
            return (false, L10n.errorClipboard)
        }
        logManager.log(LogEntry(level: .info, module: "ShareExtension", message: "Result copied to clipboard successfully", metadata: [:]))
        return (true, nil)
    }

    private func processAsync(pm: ProcessingManaging, text: String, operation: InventoryOperation) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            pm.process(text: text, operation: operation) { result in
                switch result {
                case let .success(str):
                    continuation.resume(returning: str)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Устанавливает флаг отмены обработки
    public func cancelProcessing() {
        isCancelled = true
    }

    deinit {}
}
