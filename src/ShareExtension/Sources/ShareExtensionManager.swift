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
    private let logManager: LogManagerShared
    private var isCancelled = false
    /// Последний результат обработки, используется для режима отображения
    public private(set) var lastResult: String?
    private static let maxTextLength = 5000
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
            logManager.log(LogEntry(level: .info, module: "ShareExtension", message: "Операция отменена", metadata: [:]))
            return (false, "Операция отменена")
        }
        guard !text.isEmpty else {
            logManager.log(LogEntry(level: .warning, module: "ShareExtension", message: "Нет текста для обработки", metadata: [:]))
            return (false, "Нет текста для обработки")
        }
        if text.count > Self.maxTextLength {
            logManager.log(LogEntry(level: .warning, module: "ShareExtension", message: "Текст слишком длинный для обработки", metadata: ["length": "\(text.count)"]))
            return (false, "Текст слишком длинный для обработки")
        }
        if !consentManager.getConsent() {
            logManager.log(LogEntry(level: .warning, module: "ShareExtension", message: "Требуется согласие пользователя", metadata: [:]))
            return (false, "Требуется согласие пользователя")
        }
        let apiKey: String?
        do {
            apiKey = try await authManager.getAPIKey()
        } catch {
            logManager.log(LogEntry(level: .error, module: "ShareExtension", message: "Ошибка доступа к API-ключу", metadata: ["error": "\(error)"]))
            return (false, "Ошибка доступа к API-ключу")
        }
        guard let key = apiKey, key.starts(with: "sk-") else {
            logManager.log(LogEntry(level: .error, module: "ShareExtension", message: "Неверный API-ключ", metadata: ["key": authManager.maskedAPIKey(apiKey)]))
            return (false, "Неверный API-ключ")
        }
        guard let op = operation else {
            logManager.log(LogEntry(level: .error, module: "ShareExtension", message: "Нет операции для обработки", metadata: [:]))
            return (false, "Нет операции для обработки")
        }
        logManager.log(LogEntry(level: .info, module: "ShareExtension", message: "Старт обработки", metadata: ["operation": "\(op.operation)"]))
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
                return (false, "Processing error")
            }
            switch result {
            case let .failure(err):
                logManager.log(LogEntry(level: .error, module: "ShareExtension", message: "Ошибка обработки", metadata: ["error": err.localizedDescription]))
                return (false, err.localizedDescription)
            case let .success(str):
                processedText = str
            }
        } else if let pm = processingManager as? ProcessingManaging {
            // Асинхронная обработка через continuation
            do {
                processedText = try await processAsync(pm: pm, text: text, operation: op)
            } catch {
                logManager.log(LogEntry(level: .error, module: "ShareExtension", message: "Ошибка обработки", metadata: ["error": error.localizedDescription]))
                return (false, error.localizedDescription)
            }
        } else {
            logManager.log(LogEntry(level: .error, module: "ShareExtension", message: "Processing manager unavailable", metadata: [:]))
            return (false, "Processing manager unavailable")
        }
        if isCancelled {
            isCancelled = false
            logManager.log(LogEntry(level: .info, module: "ShareExtension", message: "Операция отменена", metadata: [:]))
            return (false, "Операция отменена")
        }
        // Настройка режима обработки результата и сохранение результата
        let mode = OperationFactory.make(kind: op.operation).resultMode
        self.lastResult = processedText
        if mode == .display {
            logManager.log(LogEntry(level: .info, module: "ShareExtension", message: "Режим отображения результата: отображаем результат", metadata: [:]))
            return (true, nil)
        }
        // Копирование в буфер обмена
        if let cb = clipboardManager as? ClipboardManagerStub {
            if !cb.copy(text: processedText) {
                logManager.log(LogEntry(level: .error, module: "ShareExtension", message: "Ошибка доступа к буферу", metadata: [:]))
                return (false, "Ошибка доступа к буферу")
            }
        } else if let cb = clipboardManager as? ClipboardManaging {
            if !cb.copy(text: processedText) {
                logManager.log(LogEntry(level: .error, module: "ShareExtension", message: "Ошибка доступа к буферу", metadata: [:]))
                return (false, "Ошибка доступа к буферу")
            }
        } else {
            logManager.log(LogEntry(level: .error, module: "ShareExtension", message: "Ошибка доступа к буферу (тип)", metadata: [:]))
            return (false, "Ошибка доступа к буферу")
        }
        logManager.log(LogEntry(level: .info, module: "ShareExtension", message: "Успешное копирование результата", metadata: [:]))
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
