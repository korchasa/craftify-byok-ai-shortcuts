import XCTest

/// Отчёт операции «Найти ошибки»: исходный текст без изменений и пронумерованный список ошибок
/// с позицией, которую считает приложение, а не модель
public final class FindErrorsReportTests: XCTestCase {
    public func testTextWithoutErrorsSaysSo() {
        let report = FindErrorsReport.render(modelOutput: #"{"errors": []}"#, sourceText: "All good here.")

        XCTAssertEqual(report, "All good here.\n\n**\(L10n.findErrorsNone)**")
    }

    public func testMultipleErrorsAreListedWithLineAndColumn() {
        let source = "Hi tis is a mesage.\nIt have two lines."
        let output = """
        ```json
        {"errors": [
          {"fragment": "tis", "description": "Spelling: should be \\"this\\"."},
          {"fragment": "mesage", "description": "Spelling: should be \\"message\\"."},
          {"fragment": "It have", "description": "Grammar: should be \\"It has\\"."}
        ]}
        ```
        """

        let report = FindErrorsReport.render(modelOutput: output, sourceText: source)

        let expected = """
        Hi tis is a mesage.
        It have two lines.

        **\(L10n.findErrorsCount(3))**
        1. \(L10n.findErrorsPosition(1, 4)) — «tis»: Spelling: should be "this".
        2. \(L10n.findErrorsPosition(1, 13)) — «mesage»: Spelling: should be "message".
        3. \(L10n.findErrorsPosition(2, 1)) — «It have»: Grammar: should be "It has".
        """
        XCTAssertEqual(report, expected)
    }

    public func testRepeatedFragmentIsLocatedAfterThePreviousOne() {
        let source = "teh cat and teh dog"
        let output = #"{"errors": [{"fragment": "teh", "description": "a"}, {"fragment": "teh", "description": "b"}]}"#

        let report = FindErrorsReport.render(modelOutput: output, sourceText: source)

        XCTAssertTrue(report.contains("1. \(L10n.findErrorsPosition(1, 1)) — «teh»: a"), report)
        XCTAssertTrue(report.contains("2. \(L10n.findErrorsPosition(1, 13)) — «teh»: b"), report)
    }

    public func testFragmentMissingFromTheTextIsListedWithoutPosition() {
        let output = #"{"errors": [{"fragment": "nowhere", "description": "Invented."}]}"#

        let report = FindErrorsReport.render(modelOutput: output, sourceText: "Some text.")

        XCTAssertTrue(report.hasSuffix("1. «nowhere»: Invented."), report)
    }

    /// Результат показывается как Markdown, поэтому символы разметки исходного текста экранируются:
    /// после разбора на экране остаётся ровно то, что пользователь прислал
    public func testOriginalTextIsKeptVerbatim() throws {
        let source = "Use *stars*, _under_ and `code`  with  [links](x)\nand a second line."

        let report = FindErrorsReport.render(modelOutput: #"{"errors": []}"#, sourceText: source)

        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        let rendered = try String(AttributedString(markdown: report, options: options).characters)
        XCTAssertTrue(rendered.hasPrefix(source + "\n\n"), rendered)
    }

    public func testAnswerOutsideTheFormatIsShownAsIs() {
        let output = "1. tis → this\n2. mesage → message"

        XCTAssertEqual(FindErrorsReport.render(modelOutput: output, sourceText: "Hi tis is a mesage"), output)
    }

    public func testOperationAppliesTheReportToTheModelAnswer() {
        let operation = OperationFactory.make(kind: .findErrors)

        XCTAssertEqual(operation.resultMode, .display)
        XCTAssertEqual(
            operation.presentResult(#"{"errors": []}"#, sourceText: "Fine."),
            "Fine.\n\n**\(L10n.findErrorsNone)**"
        )
        XCTAssertEqual(OperationFactory.make(kind: .correct).presentResult("as is", sourceText: "x"), "as is")
    }
}
