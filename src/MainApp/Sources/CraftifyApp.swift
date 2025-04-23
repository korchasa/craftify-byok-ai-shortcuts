import CraftifyShared
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

    public init() {}
}
