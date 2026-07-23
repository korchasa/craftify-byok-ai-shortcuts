import Foundation

/// Локализованные подписи для канонических значений длины резюме
public enum SummarizeLengthDisplay {
    /// Локализованная подпись для канонического значения длины
    public static func label(for value: String) -> String {
        switch SummarizeLengths.normalize(value) {
        case "2-3 sentences": L10n.sentenceCount23
        case "5-6 sentences": L10n.sentenceCount56
        case "9-10 sentences": L10n.sentenceCount910
        case "18-20 sentences": L10n.sentenceCount1820
        default: value
        }
    }
}
