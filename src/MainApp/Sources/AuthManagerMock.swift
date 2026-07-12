#if DEBUG
    public final class AuthManagerMock: AuthManaging {
        public init() {}
        public func getAPIKey() -> String? {
            "sk-1234...abcd"
        }

        public func setAPIKey(_: String) {}
        public func deleteAPIKey() {}
        public func maskedAPIKey(_: String?) -> String {
            "sk-****abcd"
        }

        deinit {}
    }
#endif
