import Combine
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// NSExtensionPrincipalClass для Share Extension
public final class ShareExtensionViewController: UIViewController {
    private var hostingController: UIHostingController<ShareExtensionView>?
    private var cancellables = Set<AnyCancellable>()

    override public func viewDidLoad() {
        super.viewDidLoad()
        // Инициализация менеджеров
        let userDefaults = UserDefaults(suiteName: "group.dev.korchasa.Craftify")!
        let inventoryManager = InventoryManager(userDefaults: userDefaults)
        // Пользователь мог поделиться текстом, ни разу не открыв приложение — сетка не должна быть пустой
        inventoryManager.fillWithDefaultOperationsIfNeeded()
        let authManager = AuthManager()
        let clipboardManager = ClipboardManager()
        let logManager = OSLogManagerShared(category: "ShareExtension")
        let processingManager = ProcessingManager(
            llmClient: LLMClientFactory.make(provider: AppSettingsManager.shared.llmProvider),
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
            sheet.preferredCornerRadius = ShareExtensionViewConstants.overlayCornerRadius
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        } else if traitCollection.userInterfaceIdiom == .pad {
            // Для iPad — popover
            self.modalPresentationStyle = .popover
            if let pop = self.popoverPresentationController {
                pop.sourceView = view
                pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
                pop.permittedArrowDirections = []
            }
        }
        // Высота следует за контентом: сетка операций подгоняется, результат разворачивает шторку
        Publishers.CombineLatest3(viewModel.$contentHeight, viewModel.$displayResult, viewModel.$operations)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] contentHeight, displayResult, operations in
                self?.updatePresentationHeight(
                    contentHeight: contentHeight,
                    hasResult: displayResult != nil,
                    operationsCount: operations.count
                )
            }
            .store(in: &cancellables)
        // Load the input text from the extension context
        loadInputText()
        // Подписка на закрытие
        NotificationCenter.default.addObserver(self, selector: #selector(closeExtension), name: .closeShareExtension, object: nil)
    }

    /// Подгоняет высоту шторки/popover под контент; при показе результата разворачивает на .large()
    private func updatePresentationHeight(contentHeight: CGFloat, hasResult: Bool, operationsCount: Int) {
        let screenHeight = UIScreen.main.bounds.height
        let detentHeight = ShareExtensionViewHeight.detent(
            measuredContentHeight: contentHeight,
            operationsCount: operationsCount,
            hasResult: hasResult,
            screenHeight: screenHeight
        )
        if let sheet = sheetPresentationController {
            sheet.animateChanges {
                if let detentHeight {
                    let detent = UISheetPresentationController.Detent.custom(identifier: .init("contentHeight")) { _ in
                        detentHeight
                    }
                    sheet.detents = [detent]
                    sheet.largestUndimmedDetentIdentifier = detent.identifier
                } else {
                    sheet.detents = [.large()]
                    sheet.largestUndimmedDetentIdentifier = .large
                }
            }
        } else {
            let width = traitCollection.userInterfaceIdiom == .pad
                ? ShareExtensionViewConstants.popoverWidth
                : view.bounds.width
            let height = detentHeight ?? ShareExtensionViewHeight.maxHeight(screenHeight: screenHeight)
            preferredContentSize = CGSize(width: width, height: height)
        }
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
