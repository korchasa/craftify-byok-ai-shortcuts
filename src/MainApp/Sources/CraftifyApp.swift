import Foundation
import SwiftUI

// import NewRelic

@main
public struct CraftifyApp: App {
    @StateObject private var appState = AppState()
    private let viewModel: HomeViewModel
    public init() {
        let userDefaults = UserDefaults(suiteName: "group.dev.korchasa.Craftify") ?? .standard
        let inventoryManager = InventoryManager(userDefaults: userDefaults)
        inventoryManager.fillWithDefaultOperationsIfNeeded()
        self.viewModel = HomeViewModel(inventoryManager: inventoryManager)
        // Удалена инициализация New Relic
    }

    public var body: some Scene {
        WindowGroup {
            Group {
                if appState.isConsentGiven {
                    HomeView(viewModel: viewModel)
                } else {
                    HowToUseView(onConsent: {
                        appState.setConsentGiven(true)
                    })
                }
            }
            .frame(maxWidth: ViewConstants.rootContentMaxWidth)
        }
    }
}
