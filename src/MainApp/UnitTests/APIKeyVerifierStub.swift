@testable import MainApp
import XCTest

/// Стаб проверки API-ключа с заранее заданным результатом
final class APIKeyVerifierStub: APIKeyVerifying {
    private let outcome: APIKeyVerificationOutcome

    init(outcome: APIKeyVerificationOutcome = .valid) {
        self.outcome = outcome
    }

    func verify(key _: String, provider _: LLMProvider) async -> APIKeyVerificationOutcome {
        outcome
    }

    deinit {}
}
