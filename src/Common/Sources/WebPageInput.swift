import Foundation

// [REF:fr:input.page-text]
/// Помечает текст, загруженный по ссылке, как страницу сайта. Чистка по разметке
/// (`PageMainText`) не узнаёт меню, собранные без смысловых тегов, поэтому модель
/// получает пометку и правило: сначала выделить основную часть страницы, потом
/// работать только с ней
public enum WebPageInput {
    /// Правило для системного промпта операций, которые принимают ссылку
    public static let promptRule = """
    - If the text inside <input> is wrapped in <page>, it was taken from a web page and may still hold parts of the site around the content: menus, link lists, language lists, buttons, related articles, comments, ads, footers. First find the page's main content — the article or post the reader opened the page for, with its title — and work only on it. Never output the <page> tags.
    """

    /// Оборачивает текст страницы в пометку с адресом
    /// - Parameters:
    ///   - text: Текст, извлечённый со страницы
    ///   - url: Адрес страницы
    /// - Returns: Текст внутри `<page url="…">`
    public static func wrap(_ text: String, url: String) -> String {
        "<page url=\"\(url)\">\n\(text)\n</page>"
    }
}
