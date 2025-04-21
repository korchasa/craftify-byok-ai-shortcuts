@testable import CraftifyShared
import Nimble
import XCTest

/// Тесты для AuthManager
public final class AuthManagerTests: XCTestCase {
    private var sut: AuthManagerStub?

    override public func setUpWithError() throws {
        try super.setUpWithError()
        sut = AuthManagerStub()
    }

    override public func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    /// Проверяет установку и получение API-ключа
    public func testSetAndGetAPIKey() throws {
        let key = String(repeating: "a", count: 16)
        try sut?.setAPIKey(key)
        let fetched = try sut?.getAPIKey()
        expect(fetched) == key
    }

    /// Проверяет удаление API-ключа
    public func testDeleteAPIKey() throws {
        let key = String(repeating: "b", count: 16)
        try sut?.setAPIKey(key)
        try sut?.deleteAPIKey()
        let fetched = try sut?.getAPIKey()
        expect(fetched) == nil
    }

    /// Проверяет ошибку при установке короткого ключа
    public func testSetShortAPIKeyThrows() throws {
        let key = "short"
        expect { try self.sut?.setAPIKey(key) }.to(throwError(AuthManagerError.invalidKey))
    }

    /// Проверяет ошибку при getAPIKey, если shouldThrow выставлен
    public func testGetAPIKeyThrows() throws {
        sut?.shouldThrow = .accessDenied
        expect { try self.sut?.getAPIKey() }.to(throwError(AuthManagerError.accessDenied))
    }

    /// Проверяет ошибку при setAPIKey, если shouldThrow выставлен
    public func testSetAPIKeyThrows() throws {
        sut?.shouldThrow = .accessDenied
        expect { try self.sut?.setAPIKey("validapikey123456") }.to(throwError(AuthManagerError.accessDenied))
    }

    /// Проверяет ошибку при deleteAPIKey, если shouldThrow выставлен
    public func testDeleteAPIKeyThrows() throws {
        sut?.shouldThrow = .accessDenied
        expect { try self.sut?.deleteAPIKey() }.to(throwError(AuthManagerError.accessDenied))
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

    deinit {
        sut = nil
    }
}
