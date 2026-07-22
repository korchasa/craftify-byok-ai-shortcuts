import SwiftUI

/// Font styles for Craftify app (общий для всех модулей).
/// Все шрифты относительны к текстовым стилям и масштабируются с Dynamic Type.
/// На крупных экранах (DeviceScale.isScaledUp) берутся более крупные
/// текстовые стили, чтобы контролы масштабировались вместе с экраном.
public extension Font {
    /// Title font (Semibold; базово 22pt = title2, крупный экран 28pt = title)
    static var craftifyTitle: Font {
        .system(DeviceScale.isScaledUp ? .title : .title2, design: .default).weight(.semibold)
    }

    /// Body font (Semibold; базово 17pt = body, крупный экран 20pt = title3)
    static var craftifyBody: Font {
        .system(DeviceScale.isScaledUp ? .title3 : .body, design: .default).weight(.semibold)
    }

    /// Footnote font (Semibold; базово 13pt = footnote, крупный экран 15pt = subheadline)
    static var craftifyFootnote: Font {
        .system(DeviceScale.isScaledUp ? .subheadline : .footnote, design: .default).weight(.semibold)
    }
}
