import Foundation
import os
import SwiftUI
import UniformTypeIdentifiers

public struct HomeView: View {
    @ObservedObject public var viewModel: HomeViewModel
    @State private var showAddOperation = false
    @State private var showSettings = false
    @State private var editOperationViewModel: InventoryOperation? = nil
    @State private var editingIndex: Int? = nil
    @Environment(\.colorScheme) private var colorScheme
    @State private var editMode: EditMode = .inactive
    /// Перетаскиваемая операция; nil — перетаскивания нет
    @State private var draggingID: UUID? = nil
    /// Ячейка под пальцем: её подсвечиваем, чтобы было видно, куда ляжет плитка
    @State private var highlightedSlot: Int? = nil
    /// Ячейка, для которой открыта форма добавления
    @State private var addTargetSlot: Int = 0
    /// Операция, для которой нажали минус и ждут подтверждения
    @State private var pendingDeletion: InventoryOperation? = nil
    private var palette: MainAppColorPaletteProviding {
        ColorPaletteFactory.palette(for: colorScheme)
    }

    /// Диагностика полевого iPad-бага: шит настроек закрывался при тапе по строке модели
    fileprivate static let uiLog = OSLog(subsystem: "Internal", category: "SettingsUI")

    public init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        // Ключ остался в ресурсах без применения; трогаем, чтобы Periphery не ругался
        _ = L10n.homeOrder
    }

    public var body: some View {
        NavigationStack {
            operationsList
                // Собственная шапка вместо системного навбара: кнопка Edit должна
                // стоять в строке заголовка, а не липнуть к верхней кромке окна
                // (заметно в оконном режиме iPad)
                .safeAreaInset(edge: .top) {
                    titleBar
                }
                .toolbar(.hidden, for: .navigationBar)
                .safeAreaInset(edge: .bottom) {
                    bottomBar
                }
                // Привязка режима правки живёт ВНУТРИ NavigationStack: снаружи
                // стек подсовывает содержимому собственный editMode и затеняет
                // наш — кнопка Edit переключалась, а плитки об этом не узнавали
                .environment(\.editMode, $editMode)
        }
        .background(palette.background())
        .environment(\.colorPalette, palette)
        .alert(
            L10n.homeDeleteConfirm,
            isPresented: deletionConfirmationBinding,
            presenting: pendingDeletion,
            actions: { operation in
                Button(L10n.homeDelete, role: .destructive) { confirmDeletion(of: operation) }
                Button(L10n.editOperationCancel, role: .cancel) { pendingDeletion = nil }
            }
        )
        .sheet(isPresented: $showAddOperation, onDismiss: {}, content: {
            let addOperationViewModel = AddOperationViewModel(palette: palette.palette())
            AddOperationView(viewModel: addOperationViewModel, onSave: { op in
                viewModel.addOperation(op.with(slot: addTargetSlot))
                addOperationViewModel.cancel()
                showAddOperation = false
            })
            .environment(\.colorPalette, palette)
            .compactFormPresentation()
        })
        .sheet(
            item: $editOperationViewModel,
            onDismiss: {
                editingIndex = nil
            },
            content: { vm in
                EditOperationView(
                    viewModel: EditOperationViewModel(operation: vm, palette: palette.palette()),
                    onSave: { updatedOperation in
                        if let idx = editingIndex {
                            viewModel.updateOperation(at: idx, with: updatedOperation)
                        }
                        editingIndex = nil
                    }
                )
                .environment(\.colorPalette, palette)
                .largeFormPresentation()
            }
        )
        .sheet(isPresented: $showSettings, onDismiss: nil, content: {
            SettingsView(viewModel: SettingsViewModel())
                .environment(\.colorPalette, palette)
                // Настройки остаются на полном листе: внутри пуш в пикер моделей,
                // а половинный детент прячет его навбар и обрезает длинный список
                .largeFormPresentation()
                // Настройки закрываются только кнопками: в форме бывает несохранённый
                // ключ, а на iPad жест/клик мимо шита молча уносил ввод
                .interactiveDismissDisabled()
        })
        .onChange(of: showSettings) { newValue in
            os_log("%{public}@", log: HomeView.uiLog, type: .info, "showSettings changed: \(newValue)")
        }
    }

    /// Ячейки сетки в порядке отрисовки. Нумерация идёт снизу вверх, поэтому
    /// нулевая ячейка — левая нижняя, а новые прирастают сверху. В режиме
    /// правки сверху всегда есть свободный ряд, куда можно добавить плитку
    private var gridCells: [(slot: Int, operation: InventoryOperation?)] {
        var cells = OperationGrid.cells(for: viewModel.operations, minimumCells: 0)
        if editMode == .active {
            let columns = OperationTileConstants.columns
            let rows = Int((Double(cells.count) / Double(columns)).rounded(.up))
            let target = (rows + 1) * columns
            cells.append(contentsOf: Array(repeating: nil, count: max(0, target - cells.count)))
        }
        return OperationGrid.displayOrder(cells, columns: OperationTileConstants.columns)
    }

    /// Показ подтверждения удаления завязан на выбранную операцию
    private var deletionConfirmationBinding: Binding<Bool> {
        Binding(
            get: { pendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    pendingDeletion = nil
                }
            }
        )
    }

    // [REF:fr:ux.operation-tiles]
    /// Сетка плиток — ровно та же, что увидит пользователь в расширении.
    /// Здесь он задаёт состав и порядок плиток: перетаскивание меняет порядок,
    /// режим правки добавляет кнопки удаления
    @ViewBuilder
    private var operationsList: some View {
        if viewModel.operations.isEmpty {
            emptyState
        } else {
            // Плитки прижаты к низу, чтобы до них доставал большой палец одной
            // руки. Пустое место уходит наверх, а когда плиток больше, чем
            // помещается на экран, список прокручивается как обычно
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        operationsGrid(containerWidth: geometry.size.width)
                    }
                    .frame(minHeight: geometry.size.height, alignment: .bottom)
                }
            }
            .background(palette.background())
        }
    }

    /// Ширину контейнера сетка получает снаружи и передаёт плиткам: превью
    /// перетаскивания должно быть ровно в ячейку, а на iPad окно бывает уже экрана
    private func operationsGrid(containerWidth: CGFloat) -> some View {
        let cellWidth = OperationGridLayout.cellWidth(
            containerWidth: containerWidth,
            horizontalPadding: FormStyleConstants.titleBarHorizontalPadding
        )
        return LazyVGrid(columns: OperationGridLayout.columns, spacing: OperationTileConstants.gridSpacing) {
            ForEach(gridCells, id: \.slot) { cell in
                gridCell(slot: cell.slot, operation: cell.operation, cellWidth: cellWidth)
            }
        }
        .padding(.horizontal, FormStyleConstants.titleBarHorizontalPadding)
        .padding(.top, FormStyleConstants.dividerBottomPadding)
    }

    /// Одна ячейка сетки: плитка, кнопка добавления или пустое место.
    /// Дырка между плитками сохраняется и вне режима правки — раскладку задаёт
    /// пользователь, и она не должна схлопываться
    @ViewBuilder
    private func gridCell(slot: Int, operation: InventoryOperation?, cellWidth: CGFloat) -> some View {
        if let operation {
            operationTile(operation, at: slot, cellWidth: cellWidth)
        } else if editMode == .active {
            OperationAddCellButton(
                slot: slot,
                isHighlighted: highlightedSlot == slot,
                action: { beginAdding(at: slot) }
            )
            .onDrop(of: [UTType.text], delegate: dropDelegate(for: slot))
        } else {
            Color.clear
                .frame(height: OperationTileConstants.height)
                .accessibilityHidden(true)
        }
    }

    /// Плитка операции. Перетаскивание включается только в режиме правки —
    /// вне его тап должен открывать форму, а не начинать перенос
    @ViewBuilder
    private func operationTile(_ operation: InventoryOperation, at slot: Int, cellWidth: CGFloat) -> some View {
        let isEditing = editMode == .active
        let tile = OperationTileButton(
            operation: operation,
            palette: palette,
            isEditing: isEditing,
            onEdit: { beginEditing(operation) },
            onDelete: { pendingDeletion = operation },
            cellWidth: cellWidth,
            dragItem: isEditing ? { beginDrag(of: operation) } : nil,
            onLongPress: isEditing ? nil : { withAnimation { editMode = .active } }
        )
        if isEditing {
            tile
                .opacity(draggingID == operation.id ? OperationTileConstants.settingOpacity : 1)
                .onDrop(of: [UTType.text], delegate: dropDelegate(for: slot))
        } else {
            tile
        }
    }

    /// Открывает форму добавления для конкретной ячейки
    private func beginAdding(at slot: Int) {
        addTargetSlot = slot
        showAddOperation = true
    }

    /// Открывает форму правки для выбранной операции
    private func beginEditing(_ operation: InventoryOperation) {
        editingIndex = viewModel.operations.firstIndex { $0.id == operation.id }
        editOperationViewModel = operation
    }

    /// Удаляет подтверждённую операцию по её идентификатору
    private func confirmDeletion(of operation: InventoryOperation) {
        pendingDeletion = nil
        guard let index = viewModel.operations.firstIndex(where: { $0.id == operation.id }) else { return }
        viewModel.removeOperation(at: index)
    }

    /// Начинает перетаскивание. Сам груз системе не нужен — операция живёт в
    /// состоянии экрана, — но без зарегистрированного представления перенос
    /// не стартует
    private func beginDrag(of operation: InventoryOperation) -> NSItemProvider {
        draggingID = operation.id
        let provider = NSItemProvider()
        provider.registerDataRepresentation(
            forTypeIdentifier: UTType.plainText.identifier,
            visibility: .ownProcess
        ) { completion in
            completion(Data(operation.id.uuidString.utf8), nil)
            return nil
        }
        return provider
    }

    private func dropDelegate(for slot: Int) -> OperationDropDelegate {
        OperationDropDelegate(
            slot: slot,
            draggingID: $draggingID,
            highlightedSlot: $highlightedSlot,
            onPlace: { id, destination in viewModel.placeOperation(id: id, at: destination) }
        )
    }

    /// Пустой список: подсказка вместо белого экрана, когда операций нет
    private var emptyState: some View {
        VStack(spacing: FormStyleConstants.sectionSpacing) {
            Image(systemName: "wand.and.stars")
                .font(.largeTitle)
                .foregroundColor(palette.secondaryText())
                .accessibilityHidden(true)
            Text(L10n.homeEmptyTitle)
                .font(.craftifyBody)
                .fontWeight(.bold)
            Text(L10n.homeEmptySubtitle)
                .font(.craftifyFootnote)
                .foregroundColor(palette.secondaryText())
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, FormStyleConstants.titleBarHorizontalPadding)
        .background(palette.background())
    }

    /// Строка заголовка: крупный титул слева, Edit — на той же линии справа
    private var titleBar: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(LocalizedStringKey(L10n.homeTitle))
                .font(.largeTitle)
                .fontWeight(.bold)
            Spacer()
            // Нечего редактировать на пустом списке — кнопку прячем
            if !viewModel.operations.isEmpty {
                EditButton()
                    .font(.craftifyBody)
            }
        }
        .padding(.horizontal, FormStyleConstants.titleBarHorizontalPadding)
        .padding(.top, FormStyleConstants.sectionSpacing)
        .padding(.bottom, FormStyleConstants.dividerBottomPadding)
        .background(palette.background())
    }

    private var bottomBar: some View {
        CraftifyButtonBar(backgroundColor: palette.background()) {
            Button(action: { beginAdding(at: viewModel.firstFreeSlot) }) {
                Label(L10n.homeAddOperation, systemImage: "plus")
                    .frame(maxWidth: .infinity, minHeight: CraftifyButtonConstants.minButtonHeight)
                    .foregroundColor(palette.primaryButtonText())
            }
            .buttonStyle(CraftifyPrimaryButtonStyle())
            .accessibilityIdentifier("home_add_button")
            Button(action: { showSettings = true }) {
                Label(L10n.homeSettings, systemImage: "gearshape")
                    .frame(maxWidth: .infinity, minHeight: CraftifyButtonConstants.minButtonHeight)
                    .foregroundColor(palette.secondaryButtonText())
            }
            .buttonStyle(SettingsPrimaryButtonStyle())
            .accessibilityIdentifier("home_settings_button")
        }
    }
}

private extension View {
    /// Крупный лист формы для экранов операций и настроек. На iPhone лист
    /// растягивается до `.large`; на iPad с iOS 18 занимает размер страницы
    /// вместо тесного системного formSheet, где редактор промпта и поля были
    /// зажаты по высоте. На iPad с iOS 16/17 остаётся стандартный formSheet —
    /// системного способа увеличить его там нет.
    @ViewBuilder
    func largeFormPresentation() -> some View {
        if #available(iOS 18.0, *) {
            presentationDetents([.large])
                .presentationSizing(.page)
        } else {
            presentationDetents([.large])
        }
    }

    /// Компактный лист для коротких форм (добавление, настройки): на iPhone
    /// открывается на половину экрана с возможностью растянуть, на iPad — обычный
    /// системный formSheet. В отличие от `largeFormPresentation` не растягивает
    /// короткую форму на весь экран, из-за чего под ней зиял пустой провал.
    func compactFormPresentation() -> some View {
        presentationDetents([.medium, .large])
    }
}
