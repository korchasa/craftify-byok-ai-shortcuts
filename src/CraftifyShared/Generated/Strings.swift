// swiftlint:disable all
// Этот файл сгенерирован SwiftGen. Не редактируйте вручную.

import Foundation

/// Вспомогательный класс для корректной работы поиска бандла локализации SwiftGen.
public final class BundleTokenClass {}

/// Вспомогательный enum для поиска бандла локализации SwiftGen.
public enum BundleToken {
    /// Бандл, используемый для поиска локализованных строк SwiftGen.
    public static let bundle: Bundle = {
        #if SWIFT_PACKAGE
            return Bundle.module
        #else
            return Bundle(for: BundleTokenClass.self)
        #endif
    }()
}

/// Локализованные строки приложения Craftify. Сгенерировано SwiftGen.
public enum Strings {
    /// Cancel
    public static let addOperationCancel = tr("Localizable", "add_operation_cancel", fallback: "Cancel")
    /// Save
    public static let addOperationSave = tr("Localizable", "add_operation_save", fallback: "Save")
    /// AddOperationView
    public static let addOperationTitle = tr("Localizable", "add_operation_title", fallback: "Add Operation")
    /// Operation Type
    public static let addOperationType = tr("Localizable", "add_operation_type", fallback: "Operation Type")
    /// Cancel
    public static let editOperationCancel = tr("Localizable", "edit_operation_cancel", fallback: "Cancel")
    /// Save
    public static let editOperationSave = tr("Localizable", "edit_operation_save", fallback: "Save")
    /// EditOperationView
    public static let editOperationTitle = tr("Localizable", "edit_operation_title", fallback: "Edit Operation")
    /// Add Operation
    public static let homeAddOperation = tr("Localizable", "home_add_operation", fallback: "Add Operation")
    /// Delete
    public static let homeDelete = tr("Localizable", "home_delete", fallback: "Delete")
    /// Edit
    public static let homeEdit = tr("Localizable", "home_edit", fallback: "Edit")
    /// Settings
    public static let homeSettings = tr("Localizable", "home_settings", fallback: "Settings")
    /// HomeView
    public static let homeTitle = tr("Localizable", "home_title", fallback: "Craftify — Operations")
    /// I consent to sending text to the OpenAI cloud service
    public static let howtouseConsent = tr("Localizable", "howtouse_consent", fallback: "I consent to sending text to the OpenAI cloud service")
    /// Done
    public static let howtouseDone = tr("Localizable", "howtouse_done", fallback: "Done")
    /// Select text in any app, share to Craftify, choose an operation, and get the result instantly.
    public static let howtouseInstruction = tr("Localizable", "howtouse_instruction", fallback: "Select text in any app, share to Craftify, choose an operation, and get the result instantly.")
    /// Privacy Policy
    public static let howtousePrivacyPolicy = tr("Localizable", "howtouse_privacy_policy", fallback: "Privacy Policy")
    /// HowToUseView
    public static let howtouseTitle = tr("Localizable", "howtouse_title", fallback: "How to use Craftify")
    /// Correct
    public static let operationLabelCorrect = tr("Localizable", "operation_label_correct", fallback: "Correct")
    /// Explain
    public static let operationLabelExplain = tr("Localizable", "operation_label_explain", fallback: "Explain")
    /// Simplify
    public static let operationLabelSimplify = tr("Localizable", "operation_label_simplify", fallback: "Simplify")
    /// Operation Labels
    public static let operationLabelTranslate = tr("Localizable", "operation_label_translate", fallback: "Translate")
    /// Complexity level
    public static let operationParamComplexityLevel = tr("Localizable", "operation_param_complexity_level", fallback: "Complexity level")
    /// Detail level
    public static let operationParamDetailLevel = tr("Localizable", "operation_param_detail_level", fallback: "Detail level")
    /// Style preservation
    public static let operationParamStylePreservation = tr("Localizable", "operation_param_style_preservation", fallback: "Style preservation")
    /// Operation Params Labels
    public static let operationParamTargetLanguage = tr("Localizable", "operation_param_target_language", fallback: "Target language")
    /// Advanced
    public static let operationValueAdvanced = tr("Localizable", "operation_value_advanced", fallback: "Advanced")
    /// Picker Values
    public static let operationValueBeginner = tr("Localizable", "operation_value_beginner", fallback: "Beginner")
    /// Expert
    public static let operationValueExpert = tr("Localizable", "operation_value_expert", fallback: "Expert")
    /// Intermediate
    public static let operationValueIntermediate = tr("Localizable", "operation_value_intermediate", fallback: "Intermediate")
    /// School
    public static let operationValueSchool = tr("Localizable", "operation_value_school", fallback: "School")
    /// Student
    public static let operationValueStudent = tr("Localizable", "operation_value_student", fallback: "Student")
    /// OpenAI API Key
    public static let settingsApiKey = tr("Localizable", "settings_api_key", fallback: "OpenAI API Key")
    /// Done
    public static let settingsDone = tr("Localizable", "settings_done", fallback: "Done")
    /// SettingsView
    public static let settingsTitle = tr("Localizable", "settings_title", fallback: "Settings")
    /// Cancel
    public static let shareCancel = tr("Localizable", "share_cancel", fallback: "Cancel")
    /// Copied to clipboard
    public static let shareCopied = tr("Localizable", "share_copied", fallback: "Copied to clipboard")
    /// Share Extension UI
    public static let shareTitle = tr("Localizable", "share_title", fallback: "Craftify — Text Processing")

    /// Локализация строки по ключу
    private static func tr(_ table: String, _ key: String, fallback value: String) -> String {
        let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
        return String(format: format, locale: Locale.current)
    }
}

// swiftlint:enable all
