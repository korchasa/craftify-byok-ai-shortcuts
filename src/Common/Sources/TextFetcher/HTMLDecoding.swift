import Foundation

// [REF:fr:input.page-text]
/// Превращает байты страницы в текст в той кодировке, которую объявляет сервер или сама
/// страница. Старые русскоязычные сайты отдают KOI8-R и Windows-1251, и чтение их как
/// UTF-8 заканчивалось ошибкой «Нет текста для обработки»
public enum HTMLDecoding {
    /// Сколько первых байтов страницы просматривается в поисках тега meta с кодировкой
    private static let sniffLimit = 1024
    private static let metaCharsetPattern = #"<meta[^>]+charset\s*=\s*["']?\s*([A-Za-z0-9._:-]+)"#

    /// Декодирует страницу
    /// - Parameters:
    ///   - data: Байты ответа сервера
    ///   - declaredCharset: Кодировка из заголовка `Content-Type`, если сервер её указал
    /// - Returns: Текст страницы; `nil`, если байты не читаются в выбранной кодировке.
    ///   Без объявленной кодировки страница читается как UTF-8
    public static func decode(_ data: Data, declaredCharset: String?) -> String? {
        let charset = declaredCharset ?? metaCharset(in: data)
        let encoding = charset.flatMap(encoding(named:)) ?? .utf8
        return String(data: data, encoding: encoding)
    }

    private static func encoding(named name: String) -> String.Encoding? {
        let cfEncoding = CFStringConvertIANACharSetNameToEncoding(name as CFString)
        guard cfEncoding != kCFStringEncodingInvalidId else { return nil }
        return String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(cfEncoding))
    }

    /// Кодировка из `<meta charset>` или `<meta http-equiv="Content-Type">`. Начало
    /// страницы читается как Latin-1: так байты не теряются, а имя кодировки — латиница
    private static func metaCharset(in data: Data) -> String? {
        guard let head = String(data: data.prefix(sniffLimit), encoding: .isoLatin1),
              let regex = try? NSRegularExpression(pattern: metaCharsetPattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: head, range: NSRange(head.startIndex..., in: head)),
              let range = Range(match.range(at: 1), in: head)
        else { return nil }
        return String(head[range])
    }
}
