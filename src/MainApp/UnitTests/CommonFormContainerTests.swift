@testable import MainApp
import SwiftUI
import ViewInspector
import XCTest

final class CommonFormContainerTests: XCTestCase {
    func testRendersTitleAndContentAndButtons() throws {
        let sut = CommonFormContainer(
            title: "TestTitle",
            content: { Text("FormContent") },
            buttons: { Button("TestButton", action: {}) }
        )
        let navStack = try sut.inspect().navigationStack()
        let vStack = try navStack.vStack(0)
        // Проверяем наличие содержимого формы
        let formVStack = try vStack.vStack(1)
        let form = try formVStack.form(0)
        let contentText = try form.find(text: "FormContent")
        XCTAssertEqual(try contentText.string(), "FormContent")
        // Проверяем наличие кнопки
        let button = try vStack.button(3)
        XCTAssertEqual(try button.labelView().text().string(), "TestButton")
    }
}
