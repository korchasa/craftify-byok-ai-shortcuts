import Common

#if DEBUG
    public final class AuthManagerMock: AuthManaging {
        public init() {}
        public func getAPIKey() throws -> String? { "sk-1234...abcd" }
        public func setAPIKey(_: String) throws {}
        public func deleteAPIKey() throws {}
        public func maskedAPIKey(_: String?) -> String { "sk-****abcd" }
        deinit {}
    }
#endif
