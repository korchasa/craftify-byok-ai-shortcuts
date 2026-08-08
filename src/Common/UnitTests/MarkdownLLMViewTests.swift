import SwiftUI
import XCTest

/// Ответ модели приходит размеченным Markdown. Экран результата обязан показать
/// его оформленным: `Text` разбирает Markdown только в строковом литерале, поэтому
/// строку времени выполнения нужно превращать в `AttributedString`.
public final class MarkdownLLMViewTests: XCTestCase {
    private func rendered(_ markdown: String) -> AttributedString {
        MarkdownLLMView.attributedText(from: markdown)
    }

    /// Звёздочки жирного начертания не должны доезжать до экрана
    public func testBoldMarkersAreConsumedByTheParser() {
        let result = rendered("**TL;DR:** Idempotency means one effect.")
        XCTAssertFalse(String(result.characters).contains("**"))
        XCTAssertTrue(String(result.characters).hasPrefix("TL;DR:"))
    }

    /// Разметка не просто вырезана — начертание действительно применено
    public func testBoldRunCarriesBoldIntent() {
        let result = rendered("**TL;DR:** rest")
        let bold = result.runs.contains { run in
            run.inlinePresentationIntent?.contains(.stronglyEmphasized) == true
        }
        XCTAssertTrue(bold, "Bold run is missing: \(result.runs.map(\.range))")
    }

    /// Абзацы и переносы строк остаются: разбор идёт по строчной разметке
    public func testParagraphBreaksSurviveParsing() {
        let result = rendered("First paragraph.\n\nSecond paragraph.")
        XCTAssertTrue(String(result.characters).contains("\n\n"))
    }

    /// Заголовок не остаётся на экране решёткой — он превращается в жирную строку
    public func testAtxHeadingBecomesBoldText() {
        let result = rendered("## Details\nbody")
        let text = String(result.characters)
        XCTAssertFalse(text.contains("#"))
        XCTAssertTrue(text.hasPrefix("Details"))
    }
}
