import Foundation

public struct SummarizeParams: Codable, Equatable {
    public let length: String
    public init(length: String) {
        self.length = length
    }
}
