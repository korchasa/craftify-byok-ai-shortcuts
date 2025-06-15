import SwiftUI
#if canImport(UIKit)
    import UIKit
#endif

/// Gray secondary button used for Cancel actions on certain screens.
public struct GraySecondaryButtonStyle: ButtonStyle {
    // MARK: - Constants

    // System color scheme
    @Environment(\.colorScheme) private var colorScheme

    private enum Constants {
        /// Opacity values chosen via WCAG contrast checks to provide ≥4.5 contrast ratio in both light and dark modes.
        static let lightModeOpacity: Double = 0.2 // matches grouped secondary background
        static let darkModeOpacity: Double = 0.4 // lighter on dark background for better contrast

        static let cornerRadius: CGFloat = CraftifyButtonConstants.cornerRadius
        static let pressedScale: CGFloat = CraftifyButtonConstants.pressedScale
    }

    // MARK: - ButtonStyle

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.bold)
            .padding()
            .frame(maxWidth: .infinity)
            .background(backgroundColor())
            .cornerRadius(Constants.cornerRadius)
            .scaleEffect(configuration.isPressed ? Constants.pressedScale : 1.0)
    }

    // MARK: - Init

    public init() {}

    // MARK: - Private helpers

    private func backgroundColor() -> Color {
        let opacity = colorScheme == .dark ? Constants.darkModeOpacity : Constants.lightModeOpacity
        return Color.gray.opacity(opacity)
    }
}
