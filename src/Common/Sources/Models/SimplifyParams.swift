import Foundation

public struct SimplifyParams: Codable, Equatable {
    public let complexityLevel: ComplexityLevel
    public init(complexityLevel: ComplexityLevel) {
        self.complexityLevel = complexityLevel
    }
}
