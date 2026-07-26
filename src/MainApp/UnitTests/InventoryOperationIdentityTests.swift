import XCTest

/// Проверяет, что идентификатор операции переживает правку настройки и перестановку
public final class InventoryOperationIdentityTests: XCTestCase {
    /// Плитка остаётся той же самой: правка через форму и перенос в другую ячейку
    /// не подменяют операцию новой
    public func testIdentifierSurvivesEditAndReorder() throws {
        let params = try JSONEncoder().encode(TranslateParams(targetLanguage: "en"))
        let original = InventoryOperation(operation: .translate, params: params, colorHex: "3288bd", slot: 0)
        let neighbour = InventoryOperation(operation: .simplify, params: Data(), colorHex: "fdae61", slot: 1)

        let viewModel = EditOperationViewModel(operation: original)
        viewModel.targetLanguage = "de"
        let edited = try XCTUnwrap(viewModel.makeOperation())
        XCTAssertEqual(edited.id, original.id, "Правка настройки не должна создавать новую операцию")

        let placed = OperationGrid.place([edited, neighbour], id: edited.id, at: neighbour.slot)
        XCTAssertEqual(placed.first { $0.id == original.id }?.slot, neighbour.slot)
        XCTAssertEqual(placed.first { $0.id == original.id }?.id, original.id)
    }

    /// Правка только промпта тоже сохраняет идентификатор
    public func testIdentifierSurvivesCustomPromptEdit() {
        let original = InventoryOperation(operation: .explain, params: Data(), colorHex: "abdda4")
        XCTAssertEqual(original.with(customPrompt: "Explain like I am five").id, original.id)
    }
}
