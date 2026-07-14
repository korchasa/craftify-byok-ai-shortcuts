import SwiftUI

/// Переиспользуемый экран выбора модели: список подгружается с API провайдера,
/// поиск по подстроке. Используется в настройках и в онбординге.
public struct ModelPickerView: View {
    public let selectedModel: String
    public let availableModels: [String]
    public let isLoading: Bool
    public let loadFailed: Bool
    public let onSelect: (String) -> Void
    public let onRetry: () -> Void
    @State private var searchText = ""

    public var body: some View {
        NavigationStack {
            Group {
                if isLoading, availableModels.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if loadFailed, availableModels.isEmpty {
                    loadFailedState
                } else {
                    modelList
                }
            }
            .navigationTitle(L10n.settingsModel)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: L10n.settingsModelSearch)
        }
    }

    /// Список не загрузился — сообщение и кнопка повтора, без подставного каталога
    private var loadFailedState: some View {
        VStack(spacing: FormStyleConstants.sectionSpacing) {
            Text(L10n.settingsModelsLoadFailed)
                .font(.craftifyBody)
                .fontWeight(.regular)
                .multilineTextAlignment(.center)
            Button(L10n.settingsModelsRetry, action: onRetry)
                .font(.craftifyBody)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var modelList: some View {
        List(filteredModels, id: \.self) { model in
            Button(action: { onSelect(model) }) {
                HStack {
                    Text(model)
                        .font(.craftifyBody)
                        .fontWeight(.regular)
                    Spacer()
                    if model == selectedModel {
                        Image(systemName: "checkmark")
                            .accessibilityHidden(true)
                    }
                }
            }
            .accessibilityAddTraits(model == selectedModel ? .isSelected : [])
        }
        .listStyle(.plain)
    }

    /// Выбранная модель всегда в списке, даже если API её уже не отдаёт
    private var filteredModels: [String] {
        var models = availableModels
        if !models.contains(selectedModel), !selectedModel.isEmpty {
            models.insert(selectedModel, at: 0)
        }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return models }
        return models.filter { $0.localizedCaseInsensitiveContains(query) }
    }
}
