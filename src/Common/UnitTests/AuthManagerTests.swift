// import Common
import XCTest

/// Тесты для AuthManager
public final class AuthManagerTests: XCTestCase {
    private var sut: AuthManaging?

    override public func setUpWithError() throws {
        sut = AuthManagerStub()
    }

    override public func tearDownWithError() throws {
        sut = nil
    }

    /// Проверяет установку и получение API-ключа
    public func testSetAndGetAPIKey() async throws {
        try? await sut?.deleteAPIKey()
        let key = String(repeating: "a", count: 16)
        try await sut?.setAPIKey(key)
        let fetched = try await sut?.getAPIKey()
        XCTAssertEqual(fetched, key)
        try? await sut?.deleteAPIKey()
    }

    /// Проверяет удаление API-ключа
    public func testDeleteAPIKey() async throws {
        try? await sut?.deleteAPIKey()
        let key = String(repeating: "b", count: 16)
        try await sut?.setAPIKey(key)
        try await sut?.deleteAPIKey()
        let fetched = try await sut?.getAPIKey()
        XCTAssertNil(fetched)
    }

    /// Проверяет ошибку при установке короткого ключа
    public func testSetShortAPIKeyThrows() async throws {
        try? await sut?.deleteAPIKey()
        let key = "short"
        do {
            _ = try await self.sut?.setAPIKey(key)
            XCTFail("Ожидалось исключение, но оно не было выброшено")
        } catch {
            XCTAssertEqual(error as? AuthManagerError, AuthManagerError.invalidKey)
        }
    }

    /// Проверяет маскирование ключа
    public func testMaskedAPIKey() {
        let key = "sk-1234567890abcdef"
        let masked = sut?.maskedAPIKey(key)
        XCTAssertEqual(masked, "***************cdef")
    }

    /// Проверяет маскирование nil/короткого ключа
    public func testMaskedAPIKeyShortOrNil() {
        XCTAssertEqual(self.sut?.maskedAPIKey(nil), "********")
        XCTAssertEqual(self.sut?.maskedAPIKey("abc"), "********")
    }

    deinit {}
}
