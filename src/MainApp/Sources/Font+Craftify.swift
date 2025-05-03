import SwiftUI

/// Font styles for Craftify app
public extension Font {
    /// Title font (Semibold, 22pt)
    static var craftifyTitle: Font {
        .system(size: FontConstants.titleSize, weight: .semibold, design: .default)
    }

    /// Body font (Semibold, 17pt)
    static var craftifyBody: Font {
        .system(size: FontConstants.bodySize, weight: .semibold, design: .default)
    }

    /// Footnote font (Semibold, 13pt)
    static var craftifyFootnote: Font {
        .system(size: FontConstants.footnoteSize, weight: .semibold, design: .default)
    }
}

private enum FontConstants {
    static let titleSize: CGFloat = 22
    static let bodySize: CGFloat = 17
    static let footnoteSize: CGFloat = 13
}
