import SwiftUI

// swiftlint:disable:next explicit_import
public struct HowToUseView: View {
    private static let verticalSpacing: CGFloat = 24
    private static let topPadding: CGFloat = 32
    private static let bottomPadding: CGFloat = 32

    @ObservedObject private var viewModel: HowToUseViewModel
    private var onConsent: (() -> Void)?
    @Environment(\.colorPalette) private var palette

    public var body: some View {
        VStack(spacing: Self.verticalSpacing) {
            HowToUseTitle(topPadding: Self.topPadding)
            Divider()
                .padding(.bottom, FormStyleConstants.dividerBottomPadding)
            HowToUseInstruction()
            HowToUseConsentToggle(viewModel: viewModel)
            HowToUsePrivacyLink()
            Spacer()
            HowToUseDoneButton(viewModel: viewModel, handleDoneTapped: handleDoneTapped, bottomPadding: Self.bottomPadding)
        }
        .padding()
        .background(palette.background())
        .ignoresSafeArea()
    }

    private struct HowToUseTitle: View {
        let topPadding: CGFloat
        var body: some View {
            Text(L10n.howtouseTitle)
                .font(.craftifyTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.top, topPadding)
        }
    }

    private struct HowToUseInstruction: View {
        var body: some View {
            Text(L10n.howtouseInstruction)
                .font(.craftifyBody)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private struct HowToUseConsentToggle: View {
        @ObservedObject var viewModel: HowToUseViewModel
        var body: some View {
            Toggle(isOn: $viewModel.consentGiven) {
                Text(L10n.howtouseConsent)
                    .font(.craftifyBody)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal)
        }
    }

    private struct HowToUsePrivacyLink: View {
        @Environment(\.colorPalette) private var palette
        var body: some View {
            Link(L10n.howtousePrivacyPolicy, destination: URL(string: "https://korchasa.dev/privacy")!)
                .font(.craftifyFootnote)
                .fontWeight(.semibold)
                .foregroundColor(palette.link())
        }
    }

    private struct HowToUseDoneButton: View {
        @ObservedObject var viewModel: HowToUseViewModel
        var handleDoneTapped: () -> Void
        let bottomPadding: CGFloat
        @Environment(\.colorPalette) private var palette
        var body: some View {
            Button(action: handleDoneTapped) {
                Text(L10n.howtouseDone)
                    .font(.craftifyBody)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(palette.primaryButtonText())
            }
            .disabled(!viewModel.consentGiven)
            .accessibilityLabel(L10n.howtouseDone)
            .buttonStyle(CraftifyPrimaryButtonStyle())
            .padding(.horizontal)
            .padding(.bottom, bottomPadding)
        }
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
