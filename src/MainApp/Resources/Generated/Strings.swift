// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  /// Cancel
  internal static let addOperationCancel = L10n.tr("Localizable", "add_operation_cancel", fallback: "Cancel")
  /// Save
  internal static let addOperationSave = L10n.tr("Localizable", "add_operation_save", fallback: "Save")
  /// AddOperationView
  internal static let addOperationTitle = L10n.tr("Localizable", "add_operation_title", fallback: "Add Operation")
  /// Operation Type
  internal static let addOperationType = L10n.tr("Localizable", "add_operation_type", fallback: "Operation Type")
  /// Cancel
  internal static let editOperationCancel = L10n.tr("Localizable", "edit_operation_cancel", fallback: "Cancel")
  /// Save
  internal static let editOperationSave = L10n.tr("Localizable", "edit_operation_save", fallback: "Save")
  /// EditOperationView
  internal static let editOperationTitle = L10n.tr("Localizable", "edit_operation_title", fallback: "Edit Operation")
  /// Add Operation
  internal static let homeAddOperation = L10n.tr("Localizable", "home_add_operation", fallback: "Add Operation")
  /// Delete
  internal static let homeDelete = L10n.tr("Localizable", "home_delete", fallback: "Delete")
  /// Edit
  internal static let homeEdit = L10n.tr("Localizable", "home_edit", fallback: "Edit")
  /// Settings
  internal static let homeSettings = L10n.tr("Localizable", "home_settings", fallback: "Settings")
  /// HomeView
  internal static let homeTitle = L10n.tr("Localizable", "home_title", fallback: "Craftify — Operations")
  /// I consent to sending text to the OpenAI cloud service
  internal static let howtouseConsent = L10n.tr("Localizable", "howtouse_consent", fallback: "I consent to sending text to the OpenAI cloud service")
  /// Done
  internal static let howtouseDone = L10n.tr("Localizable", "howtouse_done", fallback: "Done")
  /// Select text in any app, share to Craftify, choose an operation, and get the result instantly.
  internal static let howtouseInstruction = L10n.tr("Localizable", "howtouse_instruction", fallback: "Select text in any app, share to Craftify, choose an operation, and get the result instantly.")
  /// Privacy Policy
  internal static let howtousePrivacyPolicy = L10n.tr("Localizable", "howtouse_privacy_policy", fallback: "Privacy Policy")
  /// HowToUseView
  internal static let howtouseTitle = L10n.tr("Localizable", "howtouse_title", fallback: "How to use Craftify")
  /// Correct
  internal static let operationLabelCorrect = L10n.tr("Localizable", "operation_label_correct", fallback: "Correct")
  /// Explain
  internal static let operationLabelExplain = L10n.tr("Localizable", "operation_label_explain", fallback: "Explain")
  /// Simplify
  internal static let operationLabelSimplify = L10n.tr("Localizable", "operation_label_simplify", fallback: "Simplify")
  /// Operation Labels
  internal static let operationLabelTranslate = L10n.tr("Localizable", "operation_label_translate", fallback: "Translate")
  /// Complexity level
  internal static let operationParamComplexityLevel = L10n.tr("Localizable", "operation_param_complexity_level", fallback: "Complexity level")
  /// Detail level
  internal static let operationParamDetailLevel = L10n.tr("Localizable", "operation_param_detail_level", fallback: "Detail level")
  /// Style preservation
  internal static let operationParamStylePreservation = L10n.tr("Localizable", "operation_param_style_preservation", fallback: "Style preservation")
  /// Operation Params Labels
  internal static let operationParamTargetLanguage = L10n.tr("Localizable", "operation_param_target_language", fallback: "Target language")
  /// Advanced
  internal static let operationValueAdvanced = L10n.tr("Localizable", "operation_value_advanced", fallback: "Advanced")
  /// Picker Values
  internal static let operationValueBeginner = L10n.tr("Localizable", "operation_value_beginner", fallback: "Beginner")
  /// Expert
  internal static let operationValueExpert = L10n.tr("Localizable", "operation_value_expert", fallback: "Expert")
  /// Intermediate
  internal static let operationValueIntermediate = L10n.tr("Localizable", "operation_value_intermediate", fallback: "Intermediate")
  /// School
  internal static let operationValueSchool = L10n.tr("Localizable", "operation_value_school", fallback: "School")
  /// Student
  internal static let operationValueStudent = L10n.tr("Localizable", "operation_value_student", fallback: "Student")
  /// OpenAI API Key
  internal static let settingsApiKey = L10n.tr("Localizable", "settings_api_key", fallback: "OpenAI API Key")
  /// Done
  internal static let settingsDone = L10n.tr("Localizable", "settings_done", fallback: "Done")
  /// SettingsView
  internal static let settingsTitle = L10n.tr("Localizable", "settings_title", fallback: "Settings")
  /// Cancel
  internal static let shareCancel = L10n.tr("Localizable", "share_cancel", fallback: "Cancel")
  /// Copied to clipboard
  internal static let shareCopied = L10n.tr("Localizable", "share_copied", fallback: "Copied to clipboard")
  /// Share Extension UI
  internal static let shareTitle = L10n.tr("Localizable", "share_title", fallback: "Craftify — Text Processing")
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
