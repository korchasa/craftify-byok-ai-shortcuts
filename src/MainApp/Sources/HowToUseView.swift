import Common

// swiftlint:disable:next explicit_import
import SwiftUI

/// Экран онбординга Craftify: инструкция, согласие, privacy policy, кнопка "Готово"
public struct HowToUseView: View {
    private static let verticalSpacing: CGFloat = 24
    private static let topPadding: CGFloat = 32
    private static let bottomPadding: CGFloat = 32

    @ObservedObject private var viewModel: HowToUseViewModel
    private var onConsent: (() -> Void)?

    public var body: some View {
        VStack(spacing: Self.verticalSpacing) {
            Text(L10n.howtouseTitle)
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
                .padding(.top, Self.topPadding)
            Text(L10n.howtouseInstruction)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Toggle(isOn: $viewModel.consentGiven) {
                Text(L10n.howtouseConsent)
                    .font(.body)
            }
            .padding(.horizontal)
            Link(L10n.howtousePrivacyPolicy, destination: URL(string: "https://korchasa.dev/privacy")!)
                .font(.footnote)
                .foregroundColor(.blue)
            Spacer()
            Button(action: handleDoneTapped) {
                Text(L10n.howtouseDone)
                    .frame(maxWidth: .infinity)
            }
            .disabled(!viewModel.consentGiven)
            .accessibilityLabel(L10n.howtouseDone)
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            .padding(.bottom, Self.bottomPadding)
        }
        .padding()
    }

    /// Инициализация с менеджером согласия
    /// - Parameter consentManager: Менеджер согласия (по умолчанию — production)
    public init(consentManager: ConsentManaging = ConsentManager(), onConsent: (() -> Void)? = nil) {
        self._viewModel = ObservedObject(wrappedValue: HowToUseViewModel(consentManager: consentManager))
        self.onConsent = onConsent
    }

    private func handleDoneTapped() {
        viewModel.saveConsent()
        if viewModel.consentGiven {
            onConsent?()
        }
    }
}
