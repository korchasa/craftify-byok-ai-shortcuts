import Common
import Foundation

public final class ProcessingManager: ProcessingManaging {
    private let llmClient: LLMAPIClient
    private let logManager: LogManagerShared
    private let authManager: AuthManaging
    private var isCancelled = false
    private enum Constants {
        static let resultPreviewLength = 128
    }

    public init(
        llmClient: LLMAPIClient = LLMAPIClient(),
        logManager: LogManagerShared = OSLogManagerShared(category: "ProcessingManager"),
        authManager: AuthManaging = AuthManager()
    ) {
        self.llmClient = llmClient
        self.logManager = logManager
        self.authManager = authManager
    }

    public func process(text: String, operation: InventoryOperation, completion: @escaping (Result<String, Error>) -> Void) {
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
        logManager.log(LogEntry(
            level: .debug,
            module: "ProcessingManager",
            message: "Запрос к OpenAI API",
            metadata: [
                "operation": operation.operation.rawValue,
                "params": paramsString,
                "promptTemplate": operation.promptTemplate,
                "apiKey": maskedKey,
                "inputTextLength": "\(text.count)"
            ]
        ))
    }

    private func logResponse(operation: InventoryOperation, text: String, result: String) {
        logManager.log(LogEntry(
            level: .debug,
            module: "ProcessingManager",
            message: "Ответ OpenAI API",
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
            message: "Ошибка OpenAI API",
            metadata: [
                "error": error.localizedDescription
            ]
        ))
    }

    private func processAsync(text: String, operation: InventoryOperation, completion: @escaping (Result<String, Error>) -> Void) async {
        do {
            let apiKey = try await authManager.getAPIKey() ?? ""
            logRequest(text: text, operation: operation, apiKey: apiKey)
            let result = try await llmClient.send(text: text, promptTemplate: operation.promptTemplate, apiKey: apiKey)
            logResponse(operation: operation, text: text, result: result)
            completion(.success(result))
        } catch {
            logError(error: error)
            print("DEBUG: completion(.failure: \(error))")
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
