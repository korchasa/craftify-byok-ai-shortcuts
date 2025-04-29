import Common
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// NSExtensionPrincipalClass для Share Extension
public final class ShareExtensionViewController: UIViewController {
    private var hostingController: UIHostingController<ShareExtensionView>?
    private var contentHeightObservation: NSKeyValueObservation?
    private enum Constants {
        static let minHeight: CGFloat = 220
        static let maxHeightMultiplier: CGFloat = 0.7
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        // Инициализация менеджеров
        let userDefaults = UserDefaults(suiteName: "group.dev.korchasa.Craftify")!
        let inventoryManager = InventoryManager(userDefaults: userDefaults)
        let authManager = AuthManager()
        let clipboardManager = ClipboardManager()
        let logManager = OSLogManagerShared(category: "ShareExtension")
        let processingManager = ProcessingManager(
            llmClient: LLMAPIClient(),
            logManager: logManager,
            authManager: authManager
        )
        let consentManager = ConsentManager(appGroupSuiteName: "group.dev.korchasa.Craftify")
        let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.dev.korchasa.Craftify")!
        let manager = ShareExtensionManager(
            inventoryManager: inventoryManager,
            authManager: authManager,
            clipboardManager: clipboardManager,
            processingManager: processingManager,
            consentManager: consentManager,
            logManager: logManager
        )
        let viewModel = ShareExtensionViewModel(manager: manager)
        let operationsCount = viewModel.operations.count
        let initialHeight = ShareExtensionViewHeight.calculate(count: operationsCount)
        // self.preferredContentSize = CGSize(width: self.view.bounds.width, height: initialHeight)
        self.preferredContentSize = CGSize(width: self.view.bounds.width, height: 300)
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
        // Load the input text from the extension context
        loadInputText()
        // Подписка на закрытие
        NotificationCenter.default.addObserver(self, selector: #selector(closeExtension), name: .closeShareExtension, object: nil)
    }

    /// Loads the shared text from the extension context and updates the view model
    private func loadInputText() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else { return }
        for item in items {
            let attachments = item.attachments ?? []
            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] item, _ in
                        if let text = item as? String {
                            DispatchQueue.main.async {
                                // Update the input text in the view model
                                self?.hostingController?.rootView.viewModel.updateInputText(text)
                            }
                        }
                    }
                    return
                }
            }
        }
    }

    deinit {}

    @objc private func closeExtension() {
        // Завершаем работу расширения
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}
