import Foundation

public struct TranslateParams: Codable, Equatable {
    public let targetLanguage: String // ISO 639-1 code
    public init(targetLanguage: String) {
        self.targetLanguage = targetLanguage
    }
}
