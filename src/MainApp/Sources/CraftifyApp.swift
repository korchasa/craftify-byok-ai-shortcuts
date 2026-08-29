import Foundation
import SwiftUI

// import NewRelic

@main
public struct CraftifyApp: App {
    @StateObject private var appState = AppState()
    private let viewModel: HomeViewModel
    /// Аргумент запуска для UI-тестов: список операций сбрасывается к дефолтному.
    /// Хранилище лежит в App Group и переживает перезапуск, поэтому тест, который
    /// что-то удаляет, без сброса испортил бы все следующие прогоны.
    private static let resetInventoryArgument = "-CraftifyResetInventory"

    public init() {
        let userDefaults = UserDefaults(suiteName: AppGroup.identifier) ?? .standard
        // Только приложение дописывает идентификаторы старым записям: расширение
        // читает то же хранилище и своей записью затёрло бы чужие UUID
        let inventoryManager = InventoryManager(userDefaults: userDefaults, migratesIdentifiers: true)
        if ProcessInfo.processInfo.arguments.contains(Self.resetInventoryArgument) {
            inventoryManager.clearInventory()
        }
        inventoryManager.fillWithDefaultOperationsIfNeeded()
        self.viewModel = HomeViewModel(inventoryManager: inventoryManager)
        // Удалена инициализация New Relic
    }

    public var body: some Scene {
        WindowGroup {
            RootView(appState: appState, viewModel: viewModel)
        }
    }
}
