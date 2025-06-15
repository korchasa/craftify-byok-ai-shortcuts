import SwiftUI

// swiftlint:disable:next explicit_import
public struct HowToUseView: View {
    private static let verticalSpacing: CGFloat = 24
    private static let topPadding: CGFloat = 32
    private static let dividerVerticalPadding: CGFloat = 8
    private static let bottomPadding: CGFloat = 24

    @ObservedObject private var viewModel: HowToUseViewModel
    private var onConsent: (() -> Void)?
    @Environment(\.colorPalette) private var palette

    public var body: some View {
        ZStack {
            // Background covers full screen but keeps content in safe area
            palette.background()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Self.verticalSpacing) {
                    HowToUseTitle(topPadding: Self.topPadding)
                    HowToUseInstruction()
                    Divider()
                        .padding(.vertical, Self.dividerVerticalPadding)
                    HowToUsePrivacyPolicyFullView()

                    // Consent text placed just above the button
                    Text(L10n.howtouseConsent)
                        .font(Font.craftifyBody)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal)

                    HowToUseAcceptButton(handleAcceptTapped: handleDoneTapped)
                        .padding(.horizontal)
                        .padding(.bottom, Self.bottomPadding)
                }
                .padding(.horizontal)
            }
        }
    }

    private struct HowToUseTitle: View {
        let topPadding: CGFloat
        var body: some View {
            Text(L10n.howtouseTitle)
                .font(Font.craftifyTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.top, topPadding)
        }
    }

    private struct HowToUseInstruction: View {
        var body: some View {
            Text(L10n.howtouseInstruction)
                .font(Font.craftifyBody)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .dynamicTypeSize(.medium ... .accessibility5)
        }
    }

    /// Privacy policy text with dynamic type and selectable content
    private struct HowToUsePrivacyPolicyFullView: View {
        var body: some View {
            Text(L10n.privacyPolicyFull)
                .font(.body)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .dynamicTypeSize(.small ... .accessibility5)
                .textSelection(.enabled)
                .accessibilityIdentifier("privacyPolicyText")
        }
    }

    private struct HowToUseAcceptButton: View {
        var handleAcceptTapped: () -> Void
        @Environment(\.colorPalette) private var palette
        var body: some View {
            Button(action: handleAcceptTapped) {
                Text(L10n.howtouseDone)
                    .font(Font.craftifyBody)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(palette.primaryButtonText())
            }
            .accessibilityLabel(L10n.howtouseDone)
            .buttonStyle(CraftifyPrimaryButtonStyle())
        }
    }

    /// Инициализация с менеджером согласия
    /// - Parameter consentManager: Менеджер согласия (по умолчанию — production)
    public init(consentManager: ConsentManaging = ConsentManager(), onConsent: (() -> Void)? = nil) {
        self._viewModel = ObservedObject(wrappedValue: HowToUseViewModel(consentManager: consentManager))
        self.onConsent = onConsent
    }

    private func handleDoneTapped() {
        viewModel.consentGiven = true
        viewModel.saveConsent()
        onConsent?()
    }
}
