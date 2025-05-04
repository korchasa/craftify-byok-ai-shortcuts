import Foundation
import SwiftUI

public struct BottomSheetContainerView<Content: View>: View {
    private let maxHeight: CGFloat?
    private let content: Content
    private let cornerRadius: CGFloat
    private let shadowRadius: CGFloat
    private let backgroundColor: Color

    public init(
        maxHeight: CGFloat? = nil,
        cornerRadius: CGFloat = 20,
        shadowRadius: CGFloat = 8,
        backgroundColor: Color = Color.white,
        @ViewBuilder content: () -> Content
    ) {
        self.maxHeight = maxHeight
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.backgroundColor = backgroundColor
        self.content = content()
    }

    public var body: some View {
        let horizontalPadding: CGFloat = 16
        let topPadding: CGFloat = 12
        let bottomPadding: CGFloat = 24
        VStack(spacing: 0) {
            content
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, topPadding)
        .padding(.bottom, bottomPadding)
        .background(backgroundColor)
        .clipShape(RoundedCorner(radius: cornerRadius, corners: UIRectCorner.topLeft.union(.topRight)))
        .shadow(radius: shadowRadius)
        .frame(maxWidth: .infinity)
        .frame(maxHeight: maxHeight)
        .frame(maxHeight: .infinity, alignment: .bottom)
    }
}
