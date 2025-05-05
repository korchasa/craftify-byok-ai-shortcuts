import Foundation

/// Represents a supported language (code, native name, and English name)
public struct SupportedLanguage {
    /// Language code (ISO 639-1)
    public let code: String
    /// Native name of the language
    public let name: String
    /// English name of the language
    public let englishName: String
    /// Creates a supported language
    public init(code: String, name: String, englishName: String) {
        self.code = code
        self.name = name
        self.englishName = englishName
    }
}
