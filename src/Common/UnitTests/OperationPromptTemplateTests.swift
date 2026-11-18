import XCTest

/// Общий контракт шаблонов промптов: единая разметка секций, ограничитель вокруг
/// пользовательского текста и запреты, ради которых шаблоны переписывались
public final class OperationPromptTemplateTests: XCTestCase {
    private func prompt(_ kind: OperationKind) -> String {
        OperationFactory.make(kind: kind).defaultSystemPrompt(input: OperationInput(targetLanguage: "en"))
    }

    /// Все пять шаблонов размечены одинаково: задача, правила, формат ответа
    public func testEveryDefaultPromptUsesSharedSectionLayout() {
        for kind in OperationKind.allCases {
            let text = prompt(kind)
            for section in ["<task>", "</task>", "<rules>", "</rules>", "<output>", "</output>"] {
                XCTAssertTrue(text.contains(section), "Missing \(section) in \(kind) prompt")
            }
        }
    }

    /// Текст пользователя всегда приходит в ограничителе — инструкции из него
    /// не могут притвориться параметрами операции
    public func testEveryOperationWrapsUserTextInInputDelimiters() {
        for kind in OperationKind.allCases {
            let content = OperationFactory.make(kind: kind)
                .userContent(input: OperationInput(targetLanguage: "en"), text: "PAYLOAD")
            XCTAssertTrue(content.contains("<input>\nPAYLOAD\n</input>"), "Unwrapped user text in \(kind): \(content)")
        }
    }

    /// Каждый шаблон запрещает преамбулу вокруг результата: результат Translate,
    /// Simplify и Correct уходит в буфер обмена как есть
    public func testEveryDefaultPromptForbidsPreamble() {
        for kind in OperationKind.allCases {
            XCTAssertTrue(prompt(kind).contains("no preamble"), "No preamble ban in \(kind) prompt")
        }
    }

    /// Промпт исправления больше не говорит о переводе (след копипаста)
    public func testCorrectPromptNeverMentionsTranslation() {
        let text = prompt(.correct).lowercased()
        XCTAssertFalse(text.contains("translating"), "Correct prompt still talks about translating")
        XCTAssertTrue(text.contains("never translate it"), "Correct prompt must forbid translation")
    }

    /// Упрощение работает на языке оригинала: ни системный промпт, ни
    /// user-сообщение не подмешивают целевой язык
    public func testSimplifyDoesNotAskForTranslation() {
        let messages = SimplifyOperation().makeMessages(input: OperationInput(), text: "text")
        for message in messages {
            XCTAssertFalse(message.content.contains("Target language"), "Simplify must not carry a target language")
        }
        XCTAssertTrue(prompt(.simplify).contains("never translate it"))
    }

    /// Операции, которые принимают ссылку, просят модель выделить основную часть страницы
    public func testURLOperationsAskForThePageMainContent() {
        let urlKinds = OperationKind.allCases.filter { OperationFactory.make(kind: $0).supportsURL }
        XCTAssertFalse(urlKinds.isEmpty)
        for kind in urlKinds {
            XCTAssertTrue(prompt(kind).contains(WebPageInput.promptRule), "\(kind) prompt must ask for the page's main content")
        }
    }

    /// Шаблоны с пошаговым разбором не печатают сам разбор
    public func testRewritingPromptsForbidReasoningInOutput() {
        for kind in [OperationKind.simplify, .summarize] {
            XCTAssertTrue(prompt(kind).contains("no reasoning"), "\(kind) prompt must forbid printing reasoning")
        }
    }

    /// Длины в примерах Summarize взяты из тех же значений, что показывает пикер
    public func testSummarizeExampleLengthsAreCanonical() {
        let text = prompt(.summarize)
        let mentioned = text.split(separator: "\n")
            .filter { $0.contains("Length:") }
            .map { $0.replacingOccurrences(of: "Length:", with: "").trimmingCharacters(in: .whitespaces) }
        XCTAssertFalse(mentioned.isEmpty, "Summarize prompt must show the length in its examples")
        for length in mentioned {
            XCTAssertTrue(SummarizeLengths.all.contains(length), "Unknown length in example: \(length)")
        }
    }

    /// Explain отдаёт готовый Markdown с TL;DR — его показывает MarkdownLLMView
    public func testExplainPromptKeepsTldrStructure() {
        XCTAssertTrue(prompt(.explain).contains("**TL;DR:**"))
    }

    /// Объяснение ограничено по длине: всплывающее окно не должно превращаться в статью
    public func testExplainPromptCapsAnswerLength() {
        XCTAssertTrue(prompt(.explain).contains("under 400 words"))
    }

    /// Ответы, которые читают на экране, делятся на короткие абзацы: без этого
    /// пересказ в 9–10 предложений приходил одним сплошным блоком
    // [REF:fr:op.readable-answers]
    public func testOnScreenAnswersAreSplitIntoParagraphs() {
        for kind in [OperationKind.summarize, .explain] {
            let text = prompt(kind)
            XCTAssertTrue(text.contains("with a blank line between them"), "\(kind) prompt must ask for paragraphs")
            XCTAssertFalse(text.contains("single paragraph"), "\(kind) prompt must not ask for a single paragraph")
        }
    }

    /// Модель повторяет форму примеров, поэтому хотя бы один пример ответа сам
    /// разбит на абзацы
    // [REF:fr:op.readable-answers]
    public func testOnScreenAnswerExamplesShowParagraphs() {
        for kind in [OperationKind.summarize, .explain] {
            let text = prompt(kind)
            guard let start = text.range(of: "<examples>"), let end = text.range(of: "</examples>") else {
                return XCTFail("\(kind) prompt has no examples")
            }
            let answers = text[start.upperBound ..< end.lowerBound]
                .components(separatedBy: "</input>")
                .dropFirst()
                .map { $0.components(separatedBy: "Target language:").first ?? $0 }
            let paragraphed = answers.contains { answer in
                answer.trimmingCharacters(in: .whitespacesAndNewlines)
                    .components(separatedBy: "\n\n")
                    .count(where: { !$0.hasPrefix("**TL;DR:**") }) >= 2
            }
            XCTAssertTrue(paragraphed, "No \(kind) example answer is split into paragraphs")
        }
    }
}
