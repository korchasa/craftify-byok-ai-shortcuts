import Foundation

public final class ProcessingManager: ProcessingManaging {
    private let llmClient: LLMClienting
    private let logManager: LogManagerShared
    private let authManager: AuthManaging
    private var isCancelled = false
    private enum Constants {
        static let resultPreviewLength = 128
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
        // if operation.operation == .summarize {
        //     // Временно: возвращаем исходный текст без LLM
        //     completion(.success(text))
        //     return
        // }
        Task {
            await self.processAsync(text: text, operation: operation, completion: completion)
        }
    }

    private func logRequest(text: String, operation: InventoryOperation, apiKey: String) {
        let maskedKey = authManager.maskedAPIKey(apiKey)
        let paramsString = if let params = try? JSONSerialization.jsonObject(with: operation.params) {
            String(describing: params)
        } else {
            "<unparsable>"
        }
        let opType = OperationFactory.make(kind: operation.operation)
        let input = try? opType.decodeInput(from: operation.params)
        let promptTemplate = input.map { opType.promptTemplate(for: $0) } ?? "<prompt unavailable>"
        logManager.log(LogEntry(
            level: .debug,
            module: "ProcessingManager",
            message: "Request to LLM API",
            metadata: [
                "operation": operation.operation.rawValue,
                "params": paramsString,
                "promptTemplate": promptTemplate,
                "apiKey": maskedKey,
                "inputTextLength": "\(text.count)"
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

    private func processAsync(text: String, operation: InventoryOperation, completion: @escaping (Result<String, Error>) -> Void) async {
        do {
            let apiKey = try await authManager.getAPIKey() ?? ""
            let opType = OperationFactory.make(kind: operation.operation)
            let input = try opType.decodeInput(from: operation.params)
            let promptTemplate = opType.promptTemplate(for: input)
            logRequest(text: text, operation: operation, apiKey: apiKey)
            let result = try await llmClient.send(text: text, promptTemplate: promptTemplate, apiKey: apiKey)
            logResponse(operation: operation, text: text, result: result)
            completion(.success(result))
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
