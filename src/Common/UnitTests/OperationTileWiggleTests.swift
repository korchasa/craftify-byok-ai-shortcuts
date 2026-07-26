import XCTest

/// Тесты дрожания плитки в режиме правки
public final class OperationTileWiggleTests: XCTestCase {
    /// Системная настройка «Уменьшение движения» гасит дрожание полностью
    public func testAmplitudeIsZeroWhenReduceMotionOn() {
        XCTAssertEqual(OperationTileWiggle.amplitude(isEditing: true, reduceMotion: true), 0)
    }

    /// Вне режима правки плитка стоит ровно
    public func testAmplitudeIsZeroOutsideEditMode() {
        XCTAssertEqual(OperationTileWiggle.amplitude(isEditing: false, reduceMotion: false), 0)
        XCTAssertEqual(OperationTileWiggle.amplitude(isEditing: false, reduceMotion: true), 0)
    }

    /// В режиме правки плитка качается
    public func testAmplitudeIsPositiveInEditMode() {
        XCTAssertGreaterThan(OperationTileWiggle.amplitude(isEditing: true, reduceMotion: false), 0)
    }

    /// Соседние плитки качаются вразнобой: фаза зависит от идентификатора
    public func testPhaseDiffersBetweenOperations() {
        let first = UUID()
        let second = UUID()
        XCTAssertEqual(OperationTileWiggle.phase(for: first), OperationTileWiggle.phase(for: first))
        XCTAssertNotEqual(OperationTileWiggle.phase(for: first), OperationTileWiggle.phase(for: second))
    }

    /// Фаза лежит внутри одного периода
    public func testPhaseStaysInsideOnePeriod() {
        for _ in 0 ..< 50 {
            let phase = OperationTileWiggle.phase(for: UUID())
            XCTAssertGreaterThanOrEqual(phase, 0)
            XCTAssertLessThan(phase, OperationTileWiggle.period)
        }
    }
}
