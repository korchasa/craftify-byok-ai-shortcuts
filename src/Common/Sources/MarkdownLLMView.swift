import SwiftUI

/// A view that renders a Markdown string received from an LLM response.
///
/// The string is parsed into an `AttributedString` and displayed using `Text`,
/// providing native Markdown rendering on iOS 15 and later with no third-party
/// dependencies.
public struct MarkdownLLMView: View {
    /// Raw Markdown text to display.
    private let markdown: String

    /// Cleaned Markdown string prepared for the SwiftUI Markdown parser.
    /// Performs lightweight, self-contained normalisation: LF line endings,
    /// bullet conversion, removal of excessive empty lines, blank line before lists.
    private var cleaned: String {
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
        return text
    }

    /// Creates a new view for the given Markdown string.
    /// - Parameter markdown: The Markdown text to render.
    public init(markdown: String) {
        self.markdown = markdown
    }

    public var body: some View {
        Text(cleaned) // SwiftUI parses Markdown natively
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
