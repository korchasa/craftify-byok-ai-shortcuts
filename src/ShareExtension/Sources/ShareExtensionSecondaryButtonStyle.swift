import SwiftUI

/// Secondary button style for ShareExtension
public struct ShareExtensionSecondaryButtonStyle: ButtonStyle {
    @Environment(\.shareExtensionColorPalette) private var palette

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.bold)
            .padding()
            .frame(maxWidth: .infinity)
            .background(palette.secondaryButton())
            .foregroundColor(palette.secondaryButtonText())
            .cornerRadius(ShareExtensionButtonConstants.buttonCornerRadius)
            .scaleEffect(configuration.isPressed ? ShareExtensionButtonConstants.buttonPressedScale : 1.0)
    }

    public init() {}
}
