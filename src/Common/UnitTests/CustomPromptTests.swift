import XCTest

/// Пользовательский системный промпт операции: подстановка в makeMessages,
/// обратная совместимость хранения и сборка дефолта из шаблона
public final class CustomPromptTests: XCTestCase {
    public func testMakeMessagesUsesCustomPromptWhenSet() {
        let op = TranslateOperation()
        let input = OperationInput(targetLanguage: "fr")
        let messages = op.makeMessages(input: input, text: "hello", customPrompt: "My custom instructions")
        XCTAssertEqual(messages.first?.content, "My custom instructions")
        XCTAssertEqual(messages.last?.content, "<input>\nhello\n</input>")
    }

    public func testMakeMessagesFallsBackToDefaultForNilOrBlankPrompt() {
        let op = TranslateOperation()
        let input = OperationInput(targetLanguage: "fr")
        let expected = op.defaultSystemPrompt(input: input)
        XCTAssertEqual(op.makeMessages(input: input, text: "t").first?.content, expected)
        XCTAssertEqual(op.makeMessages(input: input, text: "t", customPrompt: "   \n ").first?.content, expected)
    }

    public func testDefaultSystemPromptSubstitutesTargetLanguage() {
        let op = TranslateOperation()
        let prompt = op.defaultSystemPrompt(input: OperationInput(targetLanguage: "fr"))
        XCTAssertTrue(prompt.contains("French"), "Expected realized language name in prompt: \(prompt)")
    }

    public func testInventoryOperationDecodesLegacyJSONWithoutCustomPrompt() throws {
        let legacy = """
        {"operation":"translate","params":"","colorHex":"3288bd"}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(InventoryOperation.self, from: legacy)
        XCTAssertNil(decoded.customPrompt)
    }

    public func testInventoryOperationCustomPromptRoundTrip() throws {
        let op = InventoryOperation(operation: .correct, params: Data(), colorHex: "aabbcc")
            .with(customPrompt: "Fix only spelling")
        let data = try JSONEncoder().encode(op)
        let decoded = try JSONDecoder().decode(InventoryOperation.self, from: data)
        XCTAssertEqual(decoded.customPrompt, "Fix only spelling")
        XCTAssertEqual(decoded.operation, .correct)
    }

    public func testEveryOperationKindHasNonEmptyDefaultPrompt() {
        for kind in OperationKind.allCases {
            let op = OperationFactory.make(kind: kind)
            let prompt = op.defaultSystemPrompt(input: OperationInput(targetLanguage: "en"))
            XCTAssertFalse(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Empty default prompt for \(kind)")
        }
    }
}
