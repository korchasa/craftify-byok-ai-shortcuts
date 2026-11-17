import Foundation

public final class ProcessingManager: ProcessingManaging {
    private let llmClient: LLMClienting
    private let logManager: LogManagerShared
    private let authManager: AuthManaging
    private var isCancelled = false
    private enum Constants {
        static let resultPreviewLength = 128
        static let systemPreviewLength: Int = 48
        /// Не чаще одного обновления экрана за это время: разбор Markdown на каждый кусок
        /// в несколько символов тратил бы процессор впустую
        static let partialInterval: TimeInterval = 0.1
    }

    /// Creates `ProcessingManager` with a concrete `LLMClienting` instance.
    /// - Parameters:
    ///   - llmClient: Specific LLM client implementation. Defaults to factory value based on saved provider.
    ///   - logManager: Logger.
    ///   - authManager: API-key manager.
    public init(
        llmClient: LLMClienting = LLMClientFactory.make(provider: AppSettingsManager.shared.llmProvider),
        logManager: LogManagerShared = OSLogManagerShared(category: "ProcessingManager"),
        authManager: AuthManaging = AuthManager()
    ) {
        self.llmClient = llmClient
        self.logManager = logManager
        self.authManager = authManager
    }

    public func process(text: String, operation: InventoryOperation, completion: @escaping (Result<String, Error>) -> Void) {
        process(text: text, operation: operation, onPartial: nil, completion: completion)
    }

    public func process(
        text: String,
        operation: InventoryOperation,
        onPartial: ((String) -> Void)?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        Task {
            await self.processAsync(text: text, operation: operation, onPartial: onPartial, completion: completion)
        }
    }

    /// Получает ответ модели: по кускам, если операция показывает его по мере написания
    /// и кто-то ждёт промежуточный текст, иначе целиком
    private func answer(
        messages: [LLMMessage],
        apiKey: String,
        streams: Bool,
        onPartial: ((String) -> Void)?
    ) async throws -> String {
        guard streams, let onPartial else {
            return try await llmClient.send(messages: messages, apiKey: apiKey)
        }
        // [REF:fr:ux.streaming]
        var text = ""
        var lastReport = Date.distantPast
        for try await piece in llmClient.stream(messages: messages, apiKey: apiKey) {
            text += piece
            let now = Date()
            if now.timeIntervalSince(lastReport) >= Constants.partialInterval {
                lastReport = now
                onPartial(text)
            }
        }
        guard !text.isEmpty else {
            throw LLMAPIClientError.invalidResponse("Empty streamed answer")
        }
        return text
    }

    private func logRequest(operation: InventoryOperation, apiKey: String, messages: [LLMMessage]) {
        let maskedKey = authManager.maskedAPIKey(apiKey)
        let paramsString = if let params = try? JSONSerialization.jsonObject(with: operation.params) {
            String(describing: params)
        } else {
            "<unparsable>"
        }
        let inputTextLength = messages.first(where: { $0.role == .user })?.content.count ?? 0
        // Build compact preview of system prompt if exists
        let systemPreview = messages.first(where: { $0.role == .system })?.content.prefix(Constants.systemPreviewLength) ?? ""
        logManager.log(LogEntry(
            level: .debug,
            module: "ProcessingManager",
            message: "Request to LLM API",
            metadata: [
                "operation": operation.operation.rawValue,
                "params": paramsString,
                "systemPreview": String(systemPreview),
                "apiKey": maskedKey,
                "inputTextLength": "\(inputTextLength)"
            ]
        ))
    }

    private func logResponse(operation: InventoryOperation, text: String, result: String) {
        logManager.log(LogEntry(
            level: .debug,
            module: "ProcessingManager",
            message: "Response from LLM API",
            metadata: [
                "operation": operation.operation.rawValue,
                "resultPreview": String(result.prefix(Constants.resultPreviewLength)),
                "inputTextLength": "\(text.count)"
            ]
        ))
    }

    private func logError(error: Error) {
        logManager.log(LogEntry(
            level: .error,
            module: "ProcessingManager",
            message: "LLM API error",
            metadata: [
                "error": error.localizedDescription
            ]
        ))
    }

    private func processAsync(
        text: String,
        operation: InventoryOperation,
        onPartial: ((String) -> Void)?,
        completion: (Result<String, Error>) -> Void
    ) async {
        do {
            let apiKey = try await authManager.getAPIKey() ?? ""
            let opType = OperationFactory.make(kind: operation.operation)
            let input = try opType.decodeInput(from: operation.params)
            let messages = opType.makeMessages(input: input, text: text, customPrompt: operation.customPrompt)
            logRequest(operation: operation, apiKey: apiKey, messages: messages)
            let result = try await answer(messages: messages, apiKey: apiKey, streams: opType.streamsResult, onPartial: onPartial)
            logResponse(operation: operation, text: text, result: result)
            completion(.success(opType.presentResult(result, sourceText: text)))
        } catch {
            logError(error: error)
            if let llmError = error as? LLMAPIClientError {
                completion(.failure(llmError))
            } else {
                completion(.failure(error))
            }
        }
    }

    public func cancel() {
        isCancelled = true
    }

    deinit {}
}
