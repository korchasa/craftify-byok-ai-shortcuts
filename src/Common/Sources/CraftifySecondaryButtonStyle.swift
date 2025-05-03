import SwiftUI

/// Стиль второстепенной кнопки Craftify
public struct CraftifySecondaryButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(CraftifyButtonConstants.secondaryColor)
            .foregroundColor(.white)
            .cornerRadius(CraftifyButtonConstants.cornerRadius)
            .scaleEffect(configuration.isPressed ? CraftifyButtonConstants.pressedScale : 1.0)
    }

    public init() {}
}
