import Common
import NewRelic
import SwiftUI

@main
public struct CraftifyApp: App {
    public var body: some Scene {
        WindowGroup {
            let userDefaults = UserDefaults(suiteName: "group.dev.korchasa.Craftify") ?? .standard
            let inventoryManager = InventoryManager(userDefaults: userDefaults)
            let viewModel = HomeViewModel(inventoryManager: inventoryManager)
            HomeView(viewModel: viewModel)
        }
    }

    public init() {
        // New Relic initialization
        if let infoDict = Bundle.main.infoDictionary,
           let token = infoDict["NewRelicAppToken"] as? String,
           token != "__NEWRELIC_APP_TOKEN__"
        {
            NewRelic.start(withApplicationToken: token)
        }
    }
}
