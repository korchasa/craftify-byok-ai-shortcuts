import SwiftUI

/// Корень интерфейса: он выбирает палитру по системной теме и кладёт её в
/// окружение, поэтому каждый экран получает нужные цвета и ни один не берёт
/// светлое значение по умолчанию из ColorPaletteEnvironment
public struct RootView: View {
    @ObservedObject private var appState: AppState
    private let viewModel: HomeViewModel
    @Environment(\.colorScheme) private var colorScheme

    public init(appState: AppState, viewModel: HomeViewModel) {
        self.appState = appState
        self.viewModel = viewModel
    }

    public var body: some View {
        Group {
            if appState.isConsentGiven {
                HomeView(viewModel: viewModel)
            } else {
                HowToUseView(onConsent: {
                    appState.setConsentGiven(true)
                })
            }
        }
        .environment(\.colorPalette, ColorPaletteFactory.palette(for: colorScheme))
        .frame(maxWidth: ViewConstants.rootContentMaxWidth)
    }
}
