import SwiftUI

/// Button style used exclusively for the Save/Done action on SettingsView.
/// Applies a distinct accent colour (#88CCE2) without affecting other buttons.
public struct SettingsPrimaryButtonStyle: ButtonStyle {
    // MARK: - Constants

    private enum Constants {
        static let hexColour: String = "#88CCE2"
        static let cornerRadius: CGFloat = CraftifyButtonConstants.cornerRadius
        static let pressedScale: CGFloat = CraftifyButtonConstants.pressedScale
    }

    // MARK: - ButtonStyle

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.craftifyBody)
            .fontWeight(.bold)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(hex: Constants.hexColour))
            .cornerRadius(Constants.cornerRadius)
            .scaleEffect(configuration.isPressed ? Constants.pressedScale : 1.0)
    }

    // MARK: - Init

    public init() {}
}
