@testable import CraftifyShared
import Nimble
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
        expect(fetched) == key
        try? await sut?.deleteAPIKey()
    }

    /// Проверяет удаление API-ключа
    public func testDeleteAPIKey() async throws {
        try? await sut?.deleteAPIKey()
        let key = String(repeating: "b", count: 16)
        try await sut?.setAPIKey(key)
        try await sut?.deleteAPIKey()
        let fetched = try await sut?.getAPIKey()
        expect(fetched) == nil
    }

    /// Проверяет ошибку при установке короткого ключа
    public func testSetShortAPIKeyThrows() async throws {
        try? await sut?.deleteAPIKey()
        let key = "short"
        await expect { try await self.sut?.setAPIKey(key) }.to(throwError(AuthManagerError.invalidKey))
    }

    /// Проверяет маскирование ключа
    public func testMaskedAPIKey() {
        let key = "sk-1234567890abcdef"
        let masked = sut?.maskedAPIKey(key)
        expect(masked?.hasPrefix("sk-")) == true
        expect(masked?.hasSuffix("cdef")) == true
        expect(masked?.count) == 11
    }

    /// Проверяет маскирование nil/короткого ключа
    public func testMaskedAPIKeyShortOrNil() {
        expect(self.sut?.maskedAPIKey(nil)) == "********"
        expect(self.sut?.maskedAPIKey("abc")) == "********"
    }

    deinit {}
}
