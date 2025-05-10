import Combine
import Foundation
import SwiftUI

public final class ShareExtensionViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published public var operations: [InventoryOperation] = []
    @Published public var isProcessing: Bool = false
    @Published public var progress: Double = 0.0
    @Published public var errorMessage: String? = nil
    @Published public var isInputTextTooLong: Bool = false
    @Published public var showCopiedToast: Bool = false
    @Published public var displayResult: String? = nil
    @Published public var shouldCloseExtension: Bool = false

    // MARK: - Properties

    public let manager: ShareExtensionManager
    private var currentResultMode: ResultMode = .clipboard
    public var processingTask: Task<Void, Never>? = nil
    public var progressTimer: Timer?
    public var processingTimeoutSeconds: Double = 30
    public var logContentLength: Int = 100
    private var hasCompleted = false

    private var logManager: LogManagerShared { manager.logManager }

    // MARK: - Initialization

    public init(manager: ShareExtensionManager) {
        self.manager = manager
        let input = manager.inputText
        let inputPreview = String(input.prefix(100))

        // Добавляем дополнительное логирование для отладки
        manager.logManager.log(LogEntry(
            level: .debug,
            module: "ShareExtensionViewModel",
            message: "Initializing ShareExtensionViewModel, initial input: '\(inputPreview)'",
            metadata: ["input_length": String(input.count)],
            timestamp: Date()
        ))

        // Загружаем все операции по умолчанию, а затем отфильтруем их в updateInputText когда будет доступен контент
        self.operations = manager.inventoryManager.inventory
        self.isInputTextTooLong = input.count > ShareExtensionViewModelConstants.maxInputTextLength
    }

    // MARK: - Public Methods

    public func process(operation: InventoryOperation) {
        guard !isProcessing else { return }
        hasCompleted = false

        logProcessingStart()

        currentResultMode = OperationFactory.make(kind: operation.operation, logManager: self.logManager).resultMode
        displayResult = nil

        if validateInputTextLength() {
            return
        }

        startProcessing(operation: operation)
    }

    public func updateInputText(_ text: String) {
        manager.inputText = text
        isInputTextTooLong = text.count > ShareExtensionViewModelConstants.maxInputTextLength

        logTextUpdate(text)
        updateOperationsForInput(text)
    }

    public func cancel() {
        processingTask?.cancel()
        manager.cancelProcessing()
        isProcessing = false
        progressTimer?.invalidate()
        progress = 0.0
    }

    public func hideCopiedToast() {
        showCopiedToast = false
        shouldCloseExtension = true
    }

    // MARK: - Private Methods

    private func logProcessingStart() {
        let inputPreview = String(manager.inputText.prefix(self.logContentLength))
        let isURL = OperationInput.isHttpURL(string: manager.inputText)
        manager.logManager.log(LogEntry(
            level: .debug,
            module: "ShareExtensionViewModel",
            message: "Starting processing, current input: '\(inputPreview)'",
            metadata: [
                "isURL": String(isURL),
                "operation": "N/A",
                "input_length": String(manager.inputText.count)
            ],
            timestamp: Date()
        ))
    }

    private func validateInputTextLength() -> Bool {
        if manager.inputText.count > ShareExtensionViewModelConstants.maxInputTextLength {
            logManager.log(LogEntry(
                level: .error,
                module: "ShareExtensionViewModel",
                message: "errorMessage set in validateInputTextLength: Text too long to process",
                metadata: [:],
                timestamp: Date()
            ))
            // swiftlint:disable:next nslocalizedstring_key
            errorMessage = NSLocalizedString("error_text_too_long", bundle: .main, comment: "")
            return true
        }
        return false
    }

    private func startProcessing(operation: InventoryOperation) {
        isProcessing = true
        progress = 0.0
        errorMessage = nil
        startProgressTimer()

        processingTask = Task { [weak self] in
            guard let self else { return }
            do {
                let opType = OperationFactory.make(kind: operation.operation, logManager: logManager)
                let input = createOperationInput(isURL: OperationInput.isHttpURL(string: manager.inputText))

                logOperationInput(input)

                let resolvedText = try await opType.resolveInput(input: input)

                logResolvedInput(resolvedText)

                await runProcessingWithTimeout(operation: operation, resolvedText: resolvedText)
            } catch {
                await MainActor.run {
                    self.handleProcessingError(error)
                }
            }
        }
    }

    private func startProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: ShareExtensionViewModelConstants.progressInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            if progress < ShareExtensionViewModelConstants.maxProgress {
                progress += ShareExtensionViewModelConstants.progressStep
            }
        }
    }

    private func createOperationInput(isURL: Bool) -> OperationInput {
        if isURL {
            OperationInput(
                targetLanguage: "",
                complexityLevel: .schoolchild,
                detailLevel: .schoolchild,
                sentenceCountRange: .twoToThree,
                url: manager.inputText,
                text: nil
            )
        } else {
            OperationInput(
                targetLanguage: "",
                complexityLevel: .schoolchild,
                detailLevel: .schoolchild,
                sentenceCountRange: .twoToThree,
                url: nil,
                text: manager.inputText
            )
        }
    }

    private func logOperationInput(_ input: OperationInput) {
        self.manager.logManager.log(LogEntry(
            level: .debug,
            module: "ShareExtensionViewModel",
            message: "OperationInput created",
            metadata: [
                "isURL": String(OperationInput.isHttpURL(string: manager.inputText)),
                "url": input.url ?? "nil",
                "text_preview": input.text != nil ? String(input.text!.prefix(self.logContentLength)) : "nil"
            ],
            timestamp: Date()
        ))
    }

    private func logResolvedInput(_ resolvedText: String) {
        self.manager.logManager.log(LogEntry(
            level: .debug,
            module: "ShareExtensionViewModel",
            message: "resolveInput result: '\(String(resolvedText.prefix(100)))'",
            metadata: ["resolved_length": String(resolvedText.count)],
            timestamp: Date()
        ))
    }

    private func logTextUpdate(_ text: String) {
        let inputPreview = String(text.prefix(100))
        let isURL = OperationInput.isHttpURL(string: text)
        manager.logManager.log(LogEntry(
            level: .info,
            module: "ShareExtensionViewModel",
            message: "Input text updated: '\(inputPreview)'",
            metadata: [
                "isURL": String(isURL),
                "input_length": String(text.count),
                "type": isURL ? "URL" : "TEXT"
            ],
            timestamp: Date()
        ))
    }

    private func updateOperationsForInput(_ text: String) {
        let isURL = OperationInput.isHttpURL(string: text)

        if isURL {
            self.operations = manager.inventoryManager.inventory.filter { op in
                OperationFactory.make(kind: op.operation, logManager: manager.logManager).supportsURL
            }
            manager.logManager.log(LogEntry(
                level: .info,
                module: "ShareExtensionViewModel",
                message: "Operations filtered for URL, available: \(self.operations.count)",
                metadata: ["operations": self.operations.map(\.operation.rawValue).joined(separator: ", ")],
                timestamp: Date()
            ))
        } else {
            // Для обычного текста показываем все операции
            self.operations = manager.inventoryManager.inventory
            manager.logManager.log(LogEntry(
                level: .info,
                module: "ShareExtensionViewModel",
                message: "All operations loaded for text, available: \(self.operations.count)",
                metadata: ["operations": self.operations.map(\.operation.rawValue).joined(separator: ", ")],
                timestamp: Date()
            ))
        }
    }

    private func runProcessingWithTimeout(operation: InventoryOperation, resolvedText: String) async {
        // Запускаем две задачи: обработка и таймер
        await withTaskGroup(of: (finishedFirst: Int, result: (success: Bool, error: UserFacingError?)?).self) { group in
            let processingTask = Task<(success: Bool, error: UserFacingError?)?, Never> {
                await self.manager.process(text: resolvedText, operation: operation)
            }
            let timeoutTask = Task<Void, Never> {
                let timeoutNs = self.processingTimeoutSeconds * Double(ShareExtensionViewModelConstants.nanosecondsPerSecond)
                try? await Task.sleep(nanoseconds: UInt64(timeoutNs))
            }
            group.addTask {
                let res = await processingTask.value
                return (0, res)
            }
            group.addTask {
                await timeoutTask.value
                return (1, nil)
            }
            let (finishedFirst, result) = await group.next() ?? (1, nil)
            processingTask.cancel()
            timeoutTask.cancel()
            await MainActor.run {
                handleProcessingCompletion(finishedFirst: finishedFirst, result: result)
            }
        }
    }

    private func handleProcessingCompletion(finishedFirst: Int, result: (success: Bool, error: UserFacingError?)?) {
        guard !hasCompleted else { return }
        hasCompleted = true
        progressTimer?.invalidate()
        isProcessing = false
        if finishedFirst == 1 {
            logManager.log(LogEntry(
                level: .error,
                module: "ShareExtensionViewModel",
                message: "errorMessage set in handleProcessingCompletion: Processing timeout",
                metadata: [:],
                timestamp: Date()
            ))
            // swiftlint:disable:next nslocalizedstring_key
            errorMessage = NSLocalizedString("error_timeout", bundle: .main, comment: "")
            manager.cancelProcessing()
            progress = 0.0
        } else {
            progress = ShareExtensionViewModelConstants.completeProgress
            Task { [weak self] in
                self?.handleResult(result: result)
            }
        }
    }

    private func handleResult(result: (success: Bool, error: UserFacingError?)?) {
        if let error = result?.error {
            let msg = handleUserFacingError(error)
            logManager.log(LogEntry(
                level: .error,
                module: "ShareExtensionViewModel",
                message: "errorMessage set in handleResult: \(msg)",
                metadata: [:],
                timestamp: Date()
            ))
            errorMessage = msg
        } else if result?.success == true {
            if currentResultMode == .display {
                displayResult = manager.lastResult
            } else {
                showCopiedToast = true
                shouldCloseExtension = true
            }
        }
    }

    private func handleUserFacingError(_ error: UserFacingError) -> String {
        let message: String = switch error.messageKey {
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
        // swiftlint:disable:next nslocalizedstring_key
        let advice = NSLocalizedString(error.adviceKey.rawValue, bundle: .main, comment: "")
        var details = ""
        if let underlying = error.underlyingError {
            // Локализуем details для FetchError и UserFacingError
            if let fetchError = underlying as? FetchError {
                let userError = fetchError.userFacingError
                // swiftlint:disable:next nslocalizedstring_key
                let localized = NSLocalizedString(userError.messageKey.rawValue, bundle: .main, comment: "")
                details = "\n\n\(localized)"
            } else if let userError = underlying as? UserFacingError {
                // swiftlint:disable:next nslocalizedstring_key
                let localized = NSLocalizedString(userError.messageKey.rawValue, bundle: .main, comment: "")
                details = "\n\n\(localized)"
            }
        }
        return "\(message)\n\n\(advice)\(details)"
    }

    private func handleProcessingError(_ error: Error) {
        guard !hasCompleted else { return }
        hasCompleted = true
        let errorType = String(describing: type(of: error))
        var errorMsg: String? = nil
        if let userError = error as? UserFacingError {
            errorMsg = self.handleUserFacingError(userError)
        } else if let fetchError = error as? FetchError {
            errorMsg = self.handleUserFacingError(fetchError.userFacingError)
        } else if let localized = error as? LocalizedError, let desc = localized.errorDescription {
            errorMsg = desc
        } else {
            errorMsg = UserFacingError.unknown(underlyingError: error).errorDescription
        }
        logManager.log(LogEntry(
            level: .error,
            module: "ShareExtensionViewModel",
            message: "errorMessage set in handleProcessingError: \(errorMsg ?? "nil")",
            metadata: [:],
            timestamp: Date()
        ))
        self.errorMessage = errorMsg
        self.manager.logManager.log(LogEntry(
            level: .error,
            module: "ShareExtensionViewModel",
            message: "catch error: type=\(errorType), error=\(error), errorMessage=\(errorMsg ?? "nil")",
            metadata: [:],
            timestamp: Date()
        ))
        // Логируем ошибку (старый лог оставляю для совместимости)
        self.manager.logManager.log(LogEntry(
            level: .error,
            module: "ShareExtensionViewModel",
            message: "Error during processing: \(self.errorMessage ?? String(describing: error))",
            metadata: [:],
            timestamp: Date()
        ))
    }

    deinit {
        progressTimer?.invalidate()
        processingTask?.cancel()
    }
}
