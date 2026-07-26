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
}
