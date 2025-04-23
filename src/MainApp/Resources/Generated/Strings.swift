// swiftlint:disable:next file_name one_declaration_per_file file_types_order no_grouping_extension convenience_type prefer_self_in_static_references
// Этот файл сгенерирован SwiftGen. Не редактируйте вручную.

import Foundation

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
    /// Cancel
    internal static let addOperationCancel = Self.tr("Localizable", "add_operation_cancel", fallback: "Cancel")
    /// Save
    internal static let addOperationSave = Self.tr("Localizable", "add_operation_save", fallback: "Save")
    /// AddOperationView
    internal static let addOperationTitle = Self.tr("Localizable", "add_operation_title", fallback: "Add Operation")
    /// Operation Type
    internal static let addOperationType = Self.tr("Localizable", "add_operation_type", fallback: "Operation Type")
    /// Cancel
    internal static let editOperationCancel = Self.tr("Localizable", "edit_operation_cancel", fallback: "Cancel")
    /// Save
    internal static let editOperationSave = Self.tr("Localizable", "edit_operation_save", fallback: "Save")
    /// EditOperationView
    internal static let editOperationTitle = Self.tr("Localizable", "edit_operation_title", fallback: "Edit Operation")
    /// Add Operation
    internal static let homeAddOperation = Self.tr("Localizable", "home_add_operation", fallback: "Add Operation")
    /// Delete
    internal static let homeDelete = Self.tr("Localizable", "home_delete", fallback: "Delete")
    /// Edit
    internal static let homeEdit = Self.tr("Localizable", "home_edit", fallback: "Edit")
    /// Settings
    internal static let homeSettings = Self.tr("Localizable", "home_settings", fallback: "Settings")
    /// HomeView
    internal static let homeTitle = Self.tr("Localizable", "home_title", fallback: "Craftify — Operations")
    /// I consent to sending text to the OpenAI cloud service
    internal static let howtouseConsent = Self.tr("Localizable", "howtouse_consent", fallback: "I consent to sending text to the OpenAI cloud service")
    /// Done
    internal static let howtouseDone = Self.tr("Localizable", "howtouse_done", fallback: "Done")
    /// Select text in any app, share to Craftify, choose an operation, and get the result instantly.
    internal static let howtouseInstruction = Self.tr("Localizable", "howtouse_instruction", fallback: "Select text in any app, share to Craftify, choose an operation, and get the result instantly.")
    /// Privacy Policy
    internal static let howtousePrivacyPolicy = Self.tr("Localizable", "howtouse_privacy_policy", fallback: "Privacy Policy")
    /// HowToUseView
    internal static let howtouseTitle = Self.tr("Localizable", "howtouse_title", fallback: "How to use Craftify")
    /// OpenAI API Key
    internal static let settingsApiKey = Self.tr("Localizable", "settings_api_key", fallback: "OpenAI API Key")
    /// Done
    internal static let settingsDone = Self.tr("Localizable", "settings_done", fallback: "Done")
    /// SettingsView
    internal static let settingsTitle = Self.tr("Localizable", "settings_title", fallback: "Settings")
    /// Cancel
    internal static let shareCancel = Self.tr("Localizable", "share_cancel", fallback: "Cancel")
    /// Copied to clipboard
    internal static let shareCopied = Self.tr("Localizable", "share_copied", fallback: "Copied to clipboard")
    /// Share Extension UI
    internal static let shareTitle = Self.tr("Localizable", "share_title", fallback: "Craftify — Text Processing")
    /// Translate
    internal static let operationLabelTranslate = Self.tr("Localizable", "operation_label_translate", fallback: "Translate")
    /// Simplify
    internal static let operationLabelSimplify = Self.tr("Localizable", "operation_label_simplify", fallback: "Simplify")
    /// Correct
    internal static let operationLabelCorrect = Self.tr("Localizable", "operation_label_correct", fallback: "Correct")
    /// Explain
    internal static let operationLabelExplain = Self.tr("Localizable", "operation_label_explain", fallback: "Explain")
    /// Target language
    internal static let operationParamTargetLanguage = Self.tr("Localizable", "operation_param_target_language", fallback: "Target language")
    /// Complexity level
    internal static let operationParamComplexityLevel = Self.tr("Localizable", "operation_param_complexity_level", fallback: "Complexity level")
    /// Style preservation
    internal static let operationParamStylePreservation = Self.tr("Localizable", "operation_param_style_preservation", fallback: "Style preservation")
    /// Detail level
    internal static let operationParamDetailLevel = Self.tr("Localizable", "operation_param_detail_level", fallback: "Detail level")
    /// Beginner
    internal static let operationValueBeginner = Self.tr("Localizable", "operation_value_beginner", fallback: "Beginner")
    /// Intermediate
    internal static let operationValueIntermediate = Self.tr("Localizable", "operation_value_intermediate", fallback: "Intermediate")
    /// Advanced
    internal static let operationValueAdvanced = Self.tr("Localizable", "operation_value_advanced", fallback: "Advanced")
    /// School
    internal static let operationValueSchool = Self.tr("Localizable", "operation_value_school", fallback: "School")
    /// Student
    internal static let operationValueStudent = Self.tr("Localizable", "operation_value_student", fallback: "Student")
    /// Expert
    internal static let operationValueExpert = Self.tr("Localizable", "operation_value_expert", fallback: "Expert")

    private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
        let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
        return String(format: format, locale: Locale.current, arguments: args)
    }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length nesting type_body_length type_name vertical_whitespace_opening_braces

private final class BundleToken {
    static let bundle: Bundle = {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for: BundleToken.self)
        #endif
    }()
}
