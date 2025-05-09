import SwiftUI

/// Стиль вторичной кнопки Craftify (базовый, для Common)
public struct CraftifySecondaryButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.bold)
            .padding()
            .frame(maxWidth: .infinity)
            .background(CraftifyButtonConstants.secondaryColor)
            .cornerRadius(CraftifyButtonConstants.cornerRadius)
            .scaleEffect(configuration.isPressed ? CraftifyButtonConstants.pressedScale : 1.0)
    }

    public init() {}
}
