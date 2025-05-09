import SwiftUI

/// Универсальная панель для кнопок внизу формы Craftify
public struct CraftifyButtonBar<Content: View>: View {
    private let content: () -> Content
    private let backgroundColor: Color
    public init(backgroundColor: Color, @ViewBuilder content: @escaping () -> Content) {
        self.backgroundColor = backgroundColor
        self.content = content
    }

    public var body: some View {
        HStack(spacing: CraftifyButtonConstants.horizontalPadding) {
            content()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, CraftifyButtonConstants.horizontalPadding)
        .padding(.bottom, CraftifyButtonConstants.bottomPadding)
        .background(backgroundColor.ignoresSafeArea())
        .cornerRadius(CraftifyButtonConstants.cornerRadius)
    }
}
