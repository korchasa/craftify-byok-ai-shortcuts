import SwiftUI

/// Primary button style for ShareExtension
public struct ShareExtensionPrimaryButtonStyle: ButtonStyle {
    @Environment(\.shareExtensionColorPalette) private var palette

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.craftifyBody)
            .fontWeight(.bold)
            .padding()
            .frame(maxWidth: .infinity)
            .background(palette.primaryButton())
            .foregroundColor(palette.primaryButtonText())
            .cornerRadius(CraftifyButtonConstants.cornerRadius)
            .scaleEffect(configuration.isPressed ? CraftifyButtonConstants.pressedScale : 1.0)
    }

    public init() {}
}
