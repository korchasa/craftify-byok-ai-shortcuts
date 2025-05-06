## Swift Code Style Rules

- All test classes must implement setUp and tearDown (balanced_xctest_lifecycle).
- All declarations must explicitly specify access control level (explicit_acl).
- Do not use implicitly unwrapped optionals.
- Prefer Nimble operator overloads over free matcher functions and XCTAssert (prefer_nimble).
- All classes must have an explicit deinit (required_deinit).
- Do not use magic numbers—extract them to named constants (no_magic_numbers).
- Closure bodies must not exceed 30 lines (closure_body_length).
- Do not use async without await (async_without_await).
- For generated SwiftGen localization files, missing explicit ACL and other violations are allowed if required for correct SwiftGen operation and do not break the build.
- Protocols should be named with the -ing suffix (e.g., ClipboardManaging, ProcessingManaging) for DI-friendly architecture.
- All managers must be injected via protocols for testability.
- Do not use guard let self or guard let self = self; use only guard self != nil (shorthand_optional_binding).
- Public declarations must have documentation comments (missing_docs).
- Only one declaration per file (one_declaration_per_file).
- Unused parameters must be removed or replaced with _ (unused_parameter).
- Use static instead of class in final classes (static_over_final_class).
- Prefer non-optional Data(_:) for String-to-Data conversion (non_optional_string_data_conversion).
- Do not use async let inside withTaskGroup (async_let_with_taskgroup).
- For callback-based APIs, provide async wrappers using withCheckedThrowingContinuation (callback_to_async).
- Do not use self in closures unless required (redundant_self_in_closure).
- explicit_acl — все объявления должны явно указывать уровень доступа (например, public/private/internal/fileprivate).
- no_magic_numbers — магические числа должны быть заменены на именованные константы.
- All SwiftLint and compiler warnings are treated as errors: tests and builds fail if any warning is present (warnings_as_errors).
- Для NSLocalizedString всегда указывать bundle (nslocalizedstring_require_bundle)
- missing_docs: Все public-элементы должны иметь документацию.
- no_magic_numbers: Magic numbers запрещены, используйте именованные константы.
- closure_body_length: Тело замыкания не должно превышать 30 строк.
- Для всех новых кнопок обязательно используйте один из централизованных стилей: CraftifyPrimaryButtonStyle, CraftifySecondaryButtonStyle. Для опасных действий — secondary-стиль с .foregroundColor(.red). Локальные ButtonStyle запрещены.
- Для получения текущего языка используйте `Locale.current.language.languageCode?.identifier ?? "en"` (iOS 16+). Не используйте устаревший `Locale.current.languageCode`.

## Rule: Access Control for extensions

### extension_access_modifier
- Prefer to specify the access modifier on the `extension` itself instead of repeating it for each member.
- In an extension with an access modifier (`public`/`internal`/`private`/`fileprivate`), do not duplicate the same modifier for members — they inherit the access level of the extension.
- If only individual members require a different access level, explicitly specify the modifier only for them.

Пример:
```swift
public extension MyType {
    func foo() {}        // inherits public
    private func bar() {} // private member
}
```

- closure_body_length: Closure body should span 30 lines or less excluding comments and whitespace
- no_magic_numbers: Magic numbers should be replaced by named constants
- All style parameters for buttons (colors, radius, padding, scale) and palettes must be centralized in CraftifyButtonConstants and ColorPaletteConstants. Duplication or local constants for these parameters are not allowed.

## Tuist Manifests
- Для файлов Project.swift и Workspace.swift допускается отсутствие типа или extension, совпадающего с именем файла (исключение для SwiftLint: file_name).
- Для let project и let workspace допускается отсутствие явного ACL, если это требует Tuist.
- Документация (///) обязательна для public объявлений в манифестах.
- Для файлов, сгенерированных Tuist (TuistBundle+*.swift), допускается нарушение правила file_name, если это требуется для корректной работы Tuist.
