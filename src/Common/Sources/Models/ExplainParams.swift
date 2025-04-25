import Foundation

public struct ExplainParams: Codable, Equatable {
    public let detailLevel: DetailLevel
    public init(detailLevel: DetailLevel) {
        self.detailLevel = detailLevel
    }
}
