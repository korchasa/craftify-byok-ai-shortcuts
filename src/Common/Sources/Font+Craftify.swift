import SwiftUI

/// Font styles for Craftify app (общий для всех модулей).
/// Все шрифты относительны к текстовым стилям и масштабируются с Dynamic Type.
/// На iPad берутся более крупные текстовые стили, чтобы контролы
/// масштабировались, а не сохраняли iPhone-размеры.
public extension Font {
    /// Title font (Semibold; iPhone 22pt = title2, iPad 28pt = title)
    static var craftifyTitle: Font {
        .system(DeviceScale.isPad ? .title : .title2, design: .default).weight(.semibold)
    }

    /// Body font (Semibold; iPhone 17pt = body, iPad 20pt = title3)
    static var craftifyBody: Font {
        .system(DeviceScale.isPad ? .title3 : .body, design: .default).weight(.semibold)
    }

    /// Footnote font (Semibold; iPhone 13pt = footnote, iPad 15pt = subheadline)
    static var craftifyFootnote: Font {
        .system(DeviceScale.isPad ? .subheadline : .footnote, design: .default).weight(.semibold)
    }
}
