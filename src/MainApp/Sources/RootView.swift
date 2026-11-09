import StoreKit
import SwiftUI

/// Корень интерфейса: он выбирает палитру по системной теме и кладёт её в
/// окружение, поэтому каждый экран получает нужные цвета и ни один не берёт
/// светлое значение по умолчанию из ColorPaletteEnvironment
public struct RootView: View {
    @ObservedObject private var appState: AppState
    private let viewModel: HomeViewModel
    private let reviewPolicy: ReviewRequestPolicy
    private let logManager: LogManagerShared = OSLogManagerShared(category: "ReviewRequest")
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.requestReview) private var requestReview

    /// - Parameters:
    ///   - appState: согласие пользователя с политикой
    ///   - viewModel: модель главного экрана
    ///   - reviewPolicy: решает, пора ли попросить оценку в App Store
    public init(appState: AppState, viewModel: HomeViewModel, reviewPolicy: ReviewRequestPolicy) {
        self.appState = appState
        self.viewModel = viewModel
        self.reviewPolicy = reviewPolicy
    }

    /// Палитра под текущую системную тему
    private var palette: MainAppColorPaletteProviding {
        ColorPaletteFactory.palette(for: colorScheme)
    }

    /// Просит системное окно оценки, когда набралось нужное число успешных
    /// операций. Только на главном экране и только после короткой паузы, чтобы
    /// экран успел показаться; уход с переднего плана паузу отменяет.
    private func requestReviewIfDue() async {
        // [REF:fr:ux.review-request] — просьба об оценке в спокойный момент
        guard scenePhase == .active, reviewPolicy.shouldRequestReview() else { return }
        do {
            try await Task.sleep(nanoseconds: ViewConstants.reviewRequestDelayNanoseconds)
        } catch {
            return
        }
        guard reviewPolicy.shouldRequestReview() else { return }
        requestReview()
        reviewPolicy.markReviewRequested()
        logManager.log(LogEntry(
            level: .info,
            module: "RootView",
            message: "Review request: asked the system for a rating",
            metadata: [:],
            timestamp: Date()
        ))
    }

    public var body: some View {
        Group {
            if appState.isConsentGiven {
                HomeView(viewModel: viewModel)
                    // Каждый выход на передний план заново проверяет, пора ли просить оценку
                    .task(id: scenePhase) { await requestReviewIfDue() }
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
