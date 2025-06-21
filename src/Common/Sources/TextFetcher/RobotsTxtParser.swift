import Foundation

/// Простая реализация парсера robots.txt с поддержкой только `User-agent`, `Allow`, `Disallow`.
/// Алгоритм: берётся раздел для запрашиваемого user-agent (`CraftifyBot`) или `*`.
/// Из всех правил выбирается наиболее длинное совпадение с URL-путём. Если это правило `Disallow`, доступ запрещён.
public enum RobotsTxtParser {
    private struct Rule {
        let isAllow: Bool
        let path: String
    }

    private enum Constants {
        static let initialMatchedLength = 0
        static let maxDirectiveSplits = 1
        static let expectedPartsCount = 2
    }

    /// Проверяет, разрешён ли доступ к `url` по правилам robots.txt.
    /// - Parameters:
    ///   - userAgent: user-agent, например `CraftifyBot`.
    ///   - url: Полный URL, для которого нужно проверить доступ.
    ///   - robotsTxt: Содержимое robots.txt.
    /// - Returns: `true`, если доступ разрешён, иначе `false`.
    public static func isAllowed(userAgent: String, url: URL, robotsTxt: String) -> Bool {
        guard let path = url.path.removingPercentEncoding else { return true }
        // Разбиваем на секции по User-agent.
        let lines = robotsTxt.split(separator: "\n", omittingEmptySubsequences: false)
        var currentAgents: [String] = []
        var collectedRules: [Rule] = []

        func flushSection() {
            if currentAgents.contains("*") || currentAgents.map({ $0.lowercased() }).contains(userAgent.lowercased()) {
                sectionRules.forEach { collectedRules.append($0) }
            }
            sectionRules.removeAll()
            currentAgents.removeAll()
        }

        var sectionRules: [Rule] = []
        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            // Пропускаем комментарии
            guard !line.hasPrefix("#"), !line.isEmpty else { continue }
            let parts = line.split(separator: ":", maxSplits: Constants.maxDirectiveSplits)
            guard parts.count == Constants.expectedPartsCount else { continue }
            let field = parts[0].trimmingCharacters(in: .whitespaces).lowercased()
            let value = parts[1].trimmingCharacters(in: .whitespaces)
            switch field {
            case "user-agent":
                if !sectionRules.isEmpty || !currentAgents.isEmpty {
                    // Новый раздел – сбросить текущий.
                    flushSection()
                }
                currentAgents.append(value.lowercased())
            case "disallow":
                sectionRules.append(Rule(isAllow: false, path: value))
            case "allow":
                sectionRules.append(Rule(isAllow: true, path: value))
            default:
                continue
            }
        }
        // Флаш последнего раздела
        flushSection()

        if collectedRules.isEmpty { return true }

        // Выбираем правило с самой длинной строкой-совпадением
        var matchedRule: Rule?
        var matchedLength = Constants.initialMatchedLength
        for rule in collectedRules {
            guard !rule.path.isEmpty else { continue }
            if path.hasPrefix(rule.path), rule.path.count > matchedLength {
                matchedRule = rule
                matchedLength = rule.path.count
            }
        }
        // Если ничего не совпало – разрешено
        guard let rule = matchedRule else { return true }
        return rule.isAllow
    }
}
