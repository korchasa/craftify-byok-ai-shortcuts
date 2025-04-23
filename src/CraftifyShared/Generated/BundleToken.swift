import Foundation

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
