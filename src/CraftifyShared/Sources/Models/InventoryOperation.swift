import Foundation

public struct InventoryOperation: Codable, Equatable {
    public let operation: OperationType
    public let params: Data // Encoded params (type depends on operation)
    public let promptTemplate: String
    public init(operation: OperationType, params: Data, promptTemplate: String) {
        self.operation = operation
        self.params = params
        self.promptTemplate = promptTemplate
    }
}
