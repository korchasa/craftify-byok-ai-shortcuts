## Swift code style

- All test classes must implement setUp and tearDown (balanced_xctest_lifecycle)
- All declarations must explicitly specify ACL (explicit_acl)
- Do not use implicitly unwrapped optionals
- Use Nimble operator overloads instead of free matcher functions
- All classes must have an explicit deinit (required_deinit)
- Do not use magic numbers — extract to constants
- Closure body must not exceed 30 lines (closure_body_length)
- Do not use async without await
