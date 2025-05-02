import XCTest

/// Проверяет, что асинхронный вызов выбрасывает ошибку
public func XCTAssertThrowsErrorAsync(
    _ expression: @escaping () async throws -> Any,
    file: StaticString = #file,
    line: UInt = #line,
    _ errorHandler: (Error) -> Void = { _ in }
) async {
    do {
        _ = try await expression()
        XCTFail("Expected error but got success", file: file, line: line)
    } catch {
        errorHandler(error)
    }
}
