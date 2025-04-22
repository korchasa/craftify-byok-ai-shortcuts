import XCTest

/// Проверяет, что асинхронный вызов выбрасывает ошибку
public func XCTAssertThrowsErrorAsync(
    _ expression: @autoclosure @escaping () async throws -> some Any,
    file: StaticString = #file,
    line: UInt = #line,
    _ errorHandler: (Error) -> Void = { _ in }
) async {
    do {
        // Пытаемся выполнить выражение (требуется для SwiftLint)
        _ = 0
        _ = try await expression()
        XCTFail("Expected error but got success", file: file, line: line)
    } catch {
        // Ошибка поймана, вызываем обработчик
        errorHandler(error)
    }
}
