import Common
import SwiftUI
import UIKit

/// NSExtensionPrincipalClass для Share Extension
public final class ShareExtensionViewController: UIViewController {
    private var hostingController: UIHostingController<ShareExtensionView>?

    override public func viewDidLoad() {
        super.viewDidLoad()
        // Инициализация менеджеров
        let userDefaults = UserDefaults(suiteName: "group.dev.korchasa.Craftify")!
        let inventoryManager = InventoryManager(userDefaults: userDefaults)
        let authManager = AuthManager()
        let clipboardManager = ClipboardManager()
        let processingManager = ProcessingManager()
        let consentManager = ConsentManager(appGroupSuiteName: "group.dev.korchasa.Craftify")
        let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.dev.korchasa.Craftify")!
        let logManager = LogManagerSharedNDJSON(appGroupContainerURL: appGroupURL)
        let manager = ShareExtensionManager(
            inventoryManager: inventoryManager,
            authManager: authManager,
            clipboardManager: clipboardManager,
            processingManager: processingManager,
            consentManager: consentManager,
            logManager: logManager
        )
        let viewModel = ShareExtensionViewModel(manager: manager)
        let rootView = ShareExtensionView(viewModel: viewModel)
        let hosting = UIHostingController(rootView: rootView)
        addChild(hosting)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        hosting.didMove(toParent: self)
        self.hostingController = hosting
    }

    deinit {}
}
