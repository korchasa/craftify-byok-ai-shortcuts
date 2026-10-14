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

    /// Палитра под текущую системную тему
    private var palette: MainAppColorPaletteProviding {
        ColorPaletteFactory.palette(for: colorScheme)
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
        .environment(\.colorPalette, palette)
        .frame(maxWidth: ViewConstants.rootContentMaxWidth)
        // Поля по бокам от колонки на iPad красим фоном экрана. Без этого там
        // проступал фон окна: в светлой теме он совпадает с нашим белым, а в
        // тёмной чёрный и выделялся полосами рядом с тёмно-серой колонкой
        .frame(maxWidth: .infinity)
        .background(palette.background().ignoresSafeArea())
    }
}
