import Foundation

/// Собирает экран результата операции «Найти ошибки»: исходный текст без изменений и под ним
/// пронумерованный список ошибок. Модель возвращает только фрагменты и описания, а строку и столбец
/// считает приложение: языковые модели плохо считают символы, а поиск фрагмента в тексте точен.
public enum FindErrorsReport {
    /// Ошибка в том виде, в каком её возвращает модель
    private struct ModelError: Decodable {
        let fragment: String
        let description: String
    }

    /// Ответ модели целиком
    private struct ModelAnswer: Decodable {
        let errors: [ModelError]
    }

    /// Символы, которые разбор Markdown иначе принял бы за разметку
    private static let markdownPunctuation: Set<Character> = [
        "\\", "`", "*", "_", "[", "]", "(", ")", "~", "<", ">", "!", "#", "|", "&"
    ]

    /// Собирает отчёт для показа
    /// - Parameters:
    ///   - modelOutput: Ответ модели: JSON `{"errors": [{"fragment", "description"}]}`, возможно в блоке кода
    ///   - sourceText: Текст, который проверяли
    /// - Returns: Отчёт в Markdown; ответ модели без изменений, если он не в ожидаемом формате
    public static func render(modelOutput: String, sourceText: String) -> String {
        // [REF:fr:op.find-errors]
        guard let answer = decode(modelOutput) else {
            // Например, пользователь переписал промпт и попросил другой формат: его ответ и показываем
            return modelOutput
        }
        let original = escapeMarkdown(sourceText)
        guard !answer.errors.isEmpty else {
            return "\(original)\n\n**\(L10n.findErrorsNone)**"
        }
        var searchStart = sourceText.startIndex
        var lines = ["**\(L10n.findErrorsCount(answer.errors.count))**"]
        for (offset, error) in answer.errors.enumerated() {
            let found = locate(error.fragment, in: sourceText, from: searchStart)
            if let found {
                searchStart = found.upperBound
            }
            let position = found.map { range -> String in
                let (line, column) = lineAndColumn(of: range.lowerBound, in: sourceText)
                return "\(L10n.findErrorsPosition(line, column)) — "
            } ?? ""
            lines.append("\(offset + 1). \(position)«\(escapeMarkdown(error.fragment))»: \(error.description)")
        }
        return "\(original)\n\n" + lines.joined(separator: "\n")
    }

    /// Достаёт JSON из ответа: модели часто оборачивают его в блок кода или добавляют фразу вокруг
    private static func decode(_ output: String) -> ModelAnswer? {
        guard let open = output.firstIndex(of: "{"), let close = output.lastIndex(of: "}"), open < close else {
            return nil
        }
        let json = Data(output[open ... close].utf8)
        return try? JSONDecoder().decode(ModelAnswer.self, from: json)
    }

    /// Ищет фрагмент после предыдущей найденной ошибки, чтобы повторы указывали на разные места;
    /// если модель перечислила ошибки не по порядку, ищет с начала текста
    private static func locate(_ fragment: String, in text: String, from start: String.Index) -> Range<String.Index>? {
        guard !fragment.isEmpty else {
            return nil
        }
        return text.range(of: fragment, range: start ..< text.endIndex) ?? text.range(of: fragment)
    }

    /// Строка и столбец (с единицы) символа в тексте
    private static func lineAndColumn(of index: String.Index, in text: String) -> (line: Int, column: Int) {
        let prefix = text[text.startIndex ..< index]
        let line = prefix.filter(\.isNewline).count + 1
        let lineStart = prefix.lastIndex(where: \.isNewline).map { text.index(after: $0) } ?? text.startIndex
        return (line, text.distance(from: lineStart, to: index) + 1)
    }

    /// Экранирует символы разметки, чтобы текст показался ровно таким, каким его прислали
    private static func escapeMarkdown(_ text: String) -> String {
        var escaped = ""
        for character in text {
            if markdownPunctuation.contains(character) {
                escaped.append("\\")
            }
            escaped.append(character)
        }
        return escaped
    }
}
