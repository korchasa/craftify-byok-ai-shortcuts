import XCTest

public final class LLMProviderTests: XCTestCase {
    public func test_allCases_containsNewProviders() {
        let cases = Set(LLMProvider.allCases)
        XCTAssertTrue(cases.contains(.mistral), "LLMProvider missing .mistral")
        XCTAssertTrue(cases.contains(.openRouter), "LLMProvider missing .openRouter")
    }

    public func test_displayName_matchesExpected() {
        XCTAssertEqual(LLMProvider.mistral.displayName, "Mistral")
        XCTAssertEqual(LLMProvider.openRouter.displayName, "OpenRouter")
    }

    deinit {}
}
