import SwiftUI

/// Универсальная панель для кнопок внизу формы Craftify. На размерах шрифта
/// «Универсального доступа» кнопки встают друг под другом: вдвоём в одной
/// строке от «Отмены» и «Сохранить» оставались первые буквы
public struct CraftifyButtonBar<Content: View>: View {
    private let content: () -> Content
    private let backgroundColor: Color
    public init(backgroundColor: Color, @ViewBuilder content: @escaping () -> Content) {
        self.backgroundColor = backgroundColor
        self.content = content
    }

    public var body: some View {
        AdaptiveStack(spacing: CraftifyButtonConstants.horizontalPadding) {
            content()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, CraftifyButtonConstants.horizontalPadding)
        .padding(.bottom, CraftifyButtonConstants.bottomPadding)
        .background(backgroundColor.ignoresSafeArea())
        .cornerRadius(CraftifyButtonConstants.cornerRadius)
    }
}
