import SwiftUI

/// Стиль основной кнопки Craftify (базовый, для Common)
public struct CraftifyPrimaryButtonStyle: ButtonStyle {
    /// Отключённая кнопка приглушается, иначе выглядела активной и обманывала тапом
    @Environment(\.isEnabled) private var isEnabled

    private enum Constants {
        static let disabledOpacity: Double = 0.4
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.craftifyBody)
            .fontWeight(.bold)
            .padding()
            .frame(maxWidth: .infinity)
            .background(CraftifyButtonConstants.primaryColor)
            .cornerRadius(CraftifyButtonConstants.cornerRadius)
            .opacity(isEnabled ? 1.0 : Constants.disabledOpacity)
            .scaleEffect(configuration.isPressed ? CraftifyButtonConstants.pressedScale : 1.0)
    }

    public init() {}
}
