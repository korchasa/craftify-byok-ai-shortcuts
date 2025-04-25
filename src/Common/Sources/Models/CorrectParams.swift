import Foundation

public struct CorrectParams: Codable, Equatable {
    /// 1=minimal, 3=maximal style preservation
    public let stylePreservationLevel: Int
    public init(stylePreservationLevel: Int) {
        self.stylePreservationLevel = stylePreservationLevel
    }
}
