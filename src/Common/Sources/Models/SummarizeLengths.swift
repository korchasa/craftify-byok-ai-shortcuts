import Foundation

/// Канонические значения длины резюме. Хранятся в params и уходят в промпт LLM,
/// поэтому всегда английские и с дефисом; в интерфейсе показываются локализованные подписи.
public enum SummarizeLengths {
    /// Все доступные варианты длины (порядок = порядок в пикере)
    public static let all = ["2-3 sentences", "5-6 sentences", "9-10 sentences", "18-20 sentences"]
    /// Значение по умолчанию для новых операций
    public static let defaultLength = all[0]

    /// Приводит сохранённое значение к каноническому. Старые записи могли хранить
    /// локализованную строку пикера (длинное тире, любой из языков приложения) —
    /// сопоставляем по диапазону цифр; неизвестное значение падает на дефолт.
    public static func normalize(_ raw: String) -> String {
        let dashed = raw.replacingOccurrences(of: "\u{2013}", with: "-")
        guard let range = dashed.range(of: #"\d+-\d+"#, options: .regularExpression) else {
            return defaultLength
        }
        let numbers = String(dashed[range])
        return all.first { $0.hasPrefix(numbers + " ") } ?? defaultLength
    }
}
