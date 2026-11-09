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
    /// Отсчёт до просьбы об оценке: начинается с закрытия экрана задачи
    @State private var reviewTrigger = ReviewPromptTrigger()

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

    /// Просит системное окно оценки, когда истёк отсчёт после закрытия экрана
    /// задачи. Открытие нового экрана или уход с переднего плана меняет номер
    /// отсчёта, и SwiftUI отменяет это ожидание.
    private func requestReviewAfterCountdown() async {
        // [REF:fr:ux.review-request] — просьба об оценке в конце законченного дела
        guard let countdown = reviewTrigger.countdown else { return }
        do {
            try await Task.sleep(nanoseconds: ViewConstants.reviewRequestDelayNanoseconds)
        } catch {
            log("Review request: countdown cancelled")
            return
        }
        guard reviewTrigger.mayAsk(afterCountdown: countdown) else { return }
        let decision = reviewPolicy.reviewDecision()
        guard decision == .due else {
            log("Review request: not asked", metadata: ["reason": decision.rawValue])
            return
        }
        requestReview()
        reviewPolicy.markReviewRequested()
        log("Review request: asked the system for a rating")
    }

    private func log(_ message: String, metadata: [String: String] = [:]) {
        logManager.log(LogEntry(level: .info, module: "RootView", message: message, metadata: metadata, timestamp: Date()))
    }

    public var body: some View {
        Group {
            if appState.isConsentGiven {
                HomeView(viewModel: viewModel, onTaskSheetChange: { isShown in
                    reviewTrigger.taskSheetChanged(isShown: isShown)
                })
                .task(id: reviewTrigger.countdown) { await requestReviewAfterCountdown() }
                .onChange(of: scenePhase) { phase in
                    reviewTrigger.foregroundChanged(isActive: phase == .active)
                }
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
