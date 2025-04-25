import Common
import Foundation

public protocol ProcessingManaging: AnyObject {
    func process(text: String, operation: InventoryOperation, completion: @escaping (Result<String, Error>) -> Void)
    func cancel()
}
