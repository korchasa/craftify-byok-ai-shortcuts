import SwiftUI

/// Базовый вторичный стиль Craftify.
/// Использует цветовую палитру из `Environment` и обеспечивает
/// корректную контрастность в светлой и тёмной схемах.
public struct CraftifySecondaryButtonStyle: ButtonStyle {
    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Constants

    private enum Constants {
        /// Определённые вручную значения прозрачности, прошедшие WCAG-проверку ≥4.5.
        static let lightOpacity: Double = 0.2
        static let darkOpacity: Double = 0.4
    }

    // MARK: - ButtonStyle

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.craftifyBody)
            .fontWeight(.bold)
            .padding()
            .frame(maxWidth: .infinity)
            .background(backgroundColor())
            .cornerRadius(CraftifyButtonConstants.cornerRadius)
            .scaleEffect(configuration.isPressed ? CraftifyButtonConstants.pressedScale : 1.0)
    }

    // MARK: - Init

    public init() {}

    // MARK: - Helpers

    private func backgroundColor() -> Color {
        let opacity = colorScheme == .dark ? Constants.darkOpacity : Constants.lightOpacity
        return Color(hex: "#B5B5B8").opacity(opacity)
    }
}
