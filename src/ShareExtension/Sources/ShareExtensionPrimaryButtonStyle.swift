import SwiftUI

/// Primary button style for ShareExtension
public struct ShareExtensionPrimaryButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(ShareExtensionButtonConstants.buttonCornerRadius)
            .scaleEffect(configuration.isPressed ? ShareExtensionButtonConstants.buttonPressedScale : 1.0)
    }
}
