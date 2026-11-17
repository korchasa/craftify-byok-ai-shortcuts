import SwiftSoup

// [REF:fr:input.page-text]
/// Выбирает со страницы текст, который читает человек: без меню, оглавления, боковых
/// панелей и подвала сайта. Иначе модель получает навигацию вперемешку со статьёй и
/// пересказывает её вместе со статьёй.
public enum PageMainText {
    /// Блоки, которые никогда не бывают текстом страницы
    private static let chromeSelector = [
        "script", "style", "noscript", "template", "nav", "aside", "form",
        "[role=navigation]", "[role=banner]", "[role=contentinfo]", "[role=complementary]",
        "[role=search]", "[aria-hidden=true]", "[hidden]"
    ].joined(separator: ", ")
    /// Шапка и подвал — служебные, только если они принадлежат сайту, а не статье
    private static let siteFrameSelector = "header, footer"
    private static let contentTags: Set<String> = ["main", "article"]
    private static let mainSelector = "main, [role=main]"
    private static let roleAttribute = "role"
    private static let mainRole = "main"
    /// Кнопка, открывающая всплывающее меню; меню — её родитель вместе с содержимым
    private static let popupToggleSelector = "[aria-haspopup]:not([aria-haspopup=false])"
    private static let bodyTag = "body"

    /// Текст основной части страницы
    /// - Parameter body: Тело разобранного документа; изменяется на месте
    /// - Returns: Текст основного блока, а если без служебных блоков ничего не осталось —
    ///   текст всего тела, чтобы не сообщать пользователю о пустой странице
    public static func text(of body: Element) throws -> String {
        let wholeText = try body.text()
        try removePopupMenus(in: body)
        try body.select(chromeSelector).remove()
        for element in try body.select(siteFrameSelector).array() where !isInsideContent(element) {
            try element.remove()
        }
        let root = try mainBlock(in: body) ?? body
        let text = try root.text()
        return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? wholeText : text
    }

    /// Размеченный основной блок; если их несколько, берётся самый длинный
    private static func mainBlock(in body: Element) throws -> Element? {
        try body.select(mainSelector).array().max { lhs, rhs in
            try lhs.text().count < rhs.text().count
        }
    }

    /// Убирает всплывающие меню: родителя каждой кнопки с `aria-haspopup`. Сам основной
    /// блок, статья и тело страницы не убираются, даже если кнопка лежит прямо в них
    private static func removePopupMenus(in body: Element) throws {
        for toggle in try body.select(popupToggleSelector).array() {
            guard let menu = toggle.parent() else { continue }
            let tag = menu.tagName()
            if tag == bodyTag || contentTags.contains(tag) || (try? menu.attr(roleAttribute)) == mainRole {
                try toggle.remove()
            } else {
                try menu.remove()
            }
        }
    }

    private static func isInsideContent(_ element: Element) -> Bool {
        element.parents().array().contains { parent in
            contentTags.contains(parent.tagName()) || (try? parent.attr(roleAttribute)) == mainRole
        }
    }
}
