import SwiftUI

/// A view that renders a Markdown string received from an LLM response.
///
/// The string is parsed into an `AttributedString` and displayed using `Text`,
/// providing native Markdown rendering on iOS 15 and later with no third-party
/// dependencies. `Text` only parses Markdown from a string literal, so a runtime
/// string has to be turned into an `AttributedString` first — otherwise the
/// response shows its raw `**markers**`.
public struct MarkdownLLMView: View {
    /// Raw Markdown text to display.
    private let markdown: String

    /// Prepares a raw LLM answer for the Markdown parser: LF line endings,
    /// bullet conversion, removal of excessive empty lines, blank line before
    /// lists, headings rewritten as bold.
    public static func normalized(_ markdown: String) -> String {
        var text = markdown.replacingOccurrences(of: "\r", with: "\n")

        // Collapse 3+ consecutive newlines to exactly two (paragraph break).
        while text.contains("\n\n\n") {
            text = text.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }

        // Convert bullet • to Markdown dash.
        let bulletRegex = try? NSRegularExpression(pattern: "(?m)^[ \\t]*•[ \\t]+", options: [])
        if let bulletRegex {
            text = bulletRegex.stringByReplacingMatches(
                in: text,
                options: [],
                range: NSRange(location: 0, length: text.utf16.count),
                withTemplate: "- "
            )
        }

        // Ensure blank line before list markers.
        let listHeadRegex = try? NSRegularExpression(pattern: "(?m)([^\\n])\\n([ \\t]*(-|\\*|\\d+\\.))", options: [])
        if let listHeadRegex {
            text = listHeadRegex.stringByReplacingMatches(
                in: text,
                options: [],
                range: NSRange(location: 0, length: text.utf16.count),
                withTemplate: "$1\n\n$2"
            )
        }

        // Inline parsing keeps line breaks but ignores block syntax, so an ATX
        // heading would stay on screen as `## Heading`. Turn it into bold text.
        let headingRegex = try? NSRegularExpression(pattern: "(?m)^[ \\t]*#{1,6}[ \\t]+(.+?)[ \\t]*#*$", options: [])
        if let headingRegex {
            text = headingRegex.stringByReplacingMatches(
                in: text,
                options: [],
                range: NSRange(location: 0, length: text.utf16.count),
                withTemplate: "**$1**"
            )
        }
        return text
    }

    /// Parses the normalised text as Markdown. Inline-only parsing is what keeps
    /// the paragraph and list line breaks: full parsing folds every block into a
    /// single run, and the answer arrives as one wall of text.
    public static func attributedText(from markdown: String) -> AttributedString {
        let text = normalized(markdown)
        let options = AttributedString.MarkdownParsingOptions(
            allowsExtendedAttributes: false,
            interpretedSyntax: .inlineOnlyPreservingWhitespace,
            failurePolicy: .returnPartiallyParsedIfPossible
        )
        guard let parsed = try? AttributedString(markdown: text, options: options) else {
            return AttributedString(text)
        }
        return parsed
    }

    /// Creates a new view for the given Markdown string.
    /// - Parameter markdown: The Markdown text to render.
    public init(markdown: String) {
        self.markdown = markdown
    }

    public var body: some View {
        Text(Self.attributedText(from: markdown))
            .font(.body)
            .lineSpacing(Self.lineSpacing)
            .padding()
            .multilineTextAlignment(.leading)
            .tint(.blue)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    // MARK: - Constants

    private static let lineSpacing: CGFloat = 4
}
