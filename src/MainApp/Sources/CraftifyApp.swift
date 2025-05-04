import Common

// import NewRelic
import SwiftUI

@main
public struct CraftifyApp: App {
    @StateObject private var appState = AppState()
    public var body: some Scene {
        WindowGroup {
            let userDefaults = UserDefaults(suiteName: "group.dev.korchasa.Craftify") ?? .standard
            let inventoryManager = InventoryManager(userDefaults: userDefaults)
            let viewModel = HomeViewModel(inventoryManager: inventoryManager)
            if appState.isConsentGiven {
                HomeView(viewModel: viewModel)
            } else {
                HowToUseView(onConsent: {
                    appState.setConsentGiven(true)
                })
            }
        }
    }

    public init() {
        // Удалена инициализация New Relic
    }
}
