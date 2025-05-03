import SwiftUI

/// Стиль основной кнопки Craftify
public struct CraftifyPrimaryButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(CraftifyButtonConstants.primaryColor)
            .foregroundColor(.white)
            .cornerRadius(CraftifyButtonConstants.cornerRadius)
            .scaleEffect(configuration.isPressed ? CraftifyButtonConstants.pressedScale : 1.0)
    }

    public init() {}
}
