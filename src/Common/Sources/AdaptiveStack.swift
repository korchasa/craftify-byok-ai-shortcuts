import SwiftUI

/// Ряд, который при крупном тексте становится столбцом. На размерах шрифта
/// из «Универсального доступа» Apple советует ставить горизонтально
/// расположенные элементы друг под другом, а не обрезать подписи
public struct AdaptiveStack<Content: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let spacing: CGFloat?
    private let content: Content

    /// Создаёт ряд, перестраиваемый в столбец
    /// - Parameters:
    ///   - spacing: Расстояние между элементами; nil — системное
    ///   - content: Элементы ряда
    public init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        // [REF:fr:ux.dynamic-type]
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: spacing))
            : AnyLayout(HStackLayout(spacing: spacing))
        layout {
            content
        }
    }
}
