import Common
import Foundation

public final class ProcessingManagerStub: NSObject {
    public var shouldFailNetwork: Bool = false
    public var shouldFailParsing: Bool = false
    private let networkErrorCode = -1
    private let parsingErrorCode = -2

    override public init() {
        super.init()
    }

    public func process(text: String, operation _: InventoryOperation, completion: @escaping (Result<String, Error>) -> Void) {
        if shouldFailNetwork {
            completion(.failure(NSError(domain: "Network", code: networkErrorCode, userInfo: [NSLocalizedDescriptionKey: "Сетевая ошибка"])))
            return
        }
        if shouldFailParsing {
            completion(.failure(NSError(domain: "Parsing", code: parsingErrorCode, userInfo: [NSLocalizedDescriptionKey: "Ошибка парсинга"])))
            return
        }
        completion(.success("Processed: \(text)"))
    }

    deinit {}
}
