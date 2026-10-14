import SwiftUI
import XCTest

/// Тесты геометрии сетки плиток
public final class OperationGridLayoutTests: XCTestCase {
    /// Две ячейки плюс промежуток и отступы дают ровно ширину контейнера
    public func testCellWidthFillsTheScreenWithGapAndPaddings() {
        let containerWidth: CGFloat = 402
        let padding: CGFloat = 16

        let width = OperationGridLayout.cellWidth(containerWidth: containerWidth, horizontalPadding: padding)

        let occupied = width * CGFloat(OperationTileConstants.columns)
            + OperationTileConstants.gridSpacing * CGFloat(OperationTileConstants.columns - 1)
            + padding * 2
        XCTAssertEqual(occupied, containerWidth, accuracy: 0.001)
    }

    /// Слишком узкий контейнер не даёт отрицательной ширины
    public func testCellWidthNeverGoesNegative() {
        XCTAssertEqual(OperationGridLayout.cellWidth(containerWidth: 10, horizontalPadding: 40), 0)
    }

    /// Обычные размеры шрифта держат две колонки, размеры «Универсального доступа» — одну
    public func testColumnCountDropsToOneAtAccessibilitySizes() {
        for size in DynamicTypeSize.allCases {
            let expected = size.isAccessibilitySize ? 1 : OperationTileConstants.columns
            XCTAssertEqual(OperationGridLayout.columnCount(for: size), expected, "\(size)")
        }
    }

    /// В одну колонку ячейка занимает всю ширину между отступами
    public func testSingleColumnCellSpansTheContainer() {
        let width = OperationGridLayout.cellWidth(containerWidth: 402, horizontalPadding: 20, columnCount: 1)
        XCTAssertEqual(width, 362, accuracy: 0.001)
    }
}
