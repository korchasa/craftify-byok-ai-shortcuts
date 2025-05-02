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
        static let sheetCornerRadius: CGFloat = 16
        static let popoverWidth: CGFloat = 400
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
        // Ограничение высоты через sheet detents (iOS 15+)
        if let sheet = self.sheetPresentationController {
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = Constants.sheetCornerRadius
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            let customDetent = UISheetPresentationController.Detent.custom(identifier: .init("fixedHeight")) { _ in
                initialHeight
            }
            sheet.detents = [customDetent]
            sheet.largestUndimmedDetentIdentifier = customDetent.identifier
        } else if traitCollection.userInterfaceIdiom == .pad {
            // Для iPad — popover
            self.modalPresentationStyle = .popover
            self.preferredContentSize = CGSize(width: Constants.popoverWidth, height: initialHeight)
            if let pop = self.popoverPresentationController {
                pop.sourceView = view
                pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
                pop.permittedArrowDirections = []
            }
        } else {
            // Для iPhone < iOS 15 — ничего не делаем (система сама решает высоту)
            self.preferredContentSize = CGSize(width: view.bounds.width, height: initialHeight)
        }
        // Load the input text from the extension context
        loadInputText()
        // Подписка на закрытие
        NotificationCenter.default.addObserver(self, selector: #selector(closeExtension), name: .closeShareExtension, object: nil)
    }

    /// Loads the shared text or URL from the extension context and updates the view model
    private func loadInputText() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else { return }
        var foundText: String?
        var foundURL: String?
        let group = DispatchGroup()
        for item in items {
            let attachments = item.attachments ?? []
            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
                        if let text = item as? String {
                            foundText = text
                        }
                        group.leave()
                    }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
                        if let url = item as? URL {
                            foundURL = url.absoluteString
                        } else if let urlString = item as? String {
                            foundURL = urlString
                        }
                        group.leave()
                    }
                }
            }
        }
        group.notify(queue: .main) { [weak self] in
            let textToUse = foundText ?? foundURL
            if let text = textToUse {
                self?.hostingController?.rootView.viewModel.updateInputText(text)
            }
        }
    }

    deinit {}

    @objc private func closeExtension() {
        // Завершаем работу расширения
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}
