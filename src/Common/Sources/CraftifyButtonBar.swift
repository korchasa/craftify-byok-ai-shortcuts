import SwiftUI

/// Универсальная панель для кнопок внизу формы Craftify
public struct CraftifyButtonBar<Content: View>: View {
    private let content: () -> Content
    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        HStack(spacing: CraftifyButtonConstants.horizontalPadding) {
            content()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, CraftifyButtonConstants.horizontalPadding)
        .padding(.bottom, CraftifyButtonConstants.bottomPadding)
        .background(Color.white.ignoresSafeArea())
        .cornerRadius(CraftifyButtonConstants.cornerRadius)
    }
}
