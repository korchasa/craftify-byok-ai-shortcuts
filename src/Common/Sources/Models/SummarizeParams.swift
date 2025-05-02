import Foundation

public struct SummarizeParams: Codable, Equatable {
    public let sentenceCountRange: SentenceCountRange
    public init(sentenceCountRange: SentenceCountRange) {
        self.sentenceCountRange = sentenceCountRange
    }
}
