import SwiftUI

/// Стиль основной кнопки Craftify (базовый, для Common)
public struct CraftifyPrimaryButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.bold)
            .padding()
            .frame(maxWidth: .infinity)
            .background(CraftifyButtonConstants.primaryColor)
            .cornerRadius(CraftifyButtonConstants.cornerRadius)
            .scaleEffect(configuration.isPressed ? CraftifyButtonConstants.pressedScale : 1.0)
    }

    public init() {}
}
