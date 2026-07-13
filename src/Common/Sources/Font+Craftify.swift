import SwiftUI

/// Font styles for Craftify app (общий для всех модулей).
/// Все шрифты относительны к текстовым стилям и масштабируются с Dynamic Type.
public extension Font {
    /// Title font (Semibold, base 22pt = title2)
    static var craftifyTitle: Font {
        .system(.title2, design: .default).weight(.semibold)
    }

    /// Body font (Semibold, base 17pt = body)
    static var craftifyBody: Font {
        .system(.body, design: .default).weight(.semibold)
    }

    /// Footnote font (Semibold, base 13pt = footnote)
    static var craftifyFootnote: Font {
        .system(.footnote, design: .default).weight(.semibold)
    }
}
