import Common
import Foundation

public final class ProcessingManager: ProcessingManaging {
    private var currentTask: URLSessionDataTask?
    private let apiURL = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let timeout: TimeInterval = 15

    public init() {}

    public func process(text: String, operation _: InventoryOperation, completion: @escaping (Result<String, Error>) -> Void) {
        // TODO: Реализовать реальную обработку через OpenAI API
        completion(.success(text))
    }

    public func cancel() {
        currentTask?.cancel()
    }

    deinit {}
}
