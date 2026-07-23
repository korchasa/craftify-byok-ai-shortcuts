import SwiftUI

/// Переиспользуемый экран выбора модели: список подгружается с API провайдера,
/// поиск по подстроке. Используется в настройках и в онбординге.
/// Без собственного NavigationStack и .searchable: системная активация поиска
/// внутри вложенной презентации на iPad сбрасывала родительский шит настроек,
/// поэтому поиск — обычный TextField, а навигацию даёт вызывающая сторона.
public struct ModelPickerView: View {
    public let selectedModel: String
    public let availableModels: [String]
    public let isLoading: Bool
    public let loadFailed: Bool
    public let onSelect: (String) -> Void
    public let onRetry: () -> Void
    @State private var searchText = ""

    public var body: some View {
        VStack(spacing: 0) {
            searchBar
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
        }
        .navigationTitle(L10n.settingsModel)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
            TextField(L10n.settingsModelSearch, text: $searchText)
                .font(.craftifyBody)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .accessibilityIdentifier("model_search_field")
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel(L10n.settingsModelSearch)
            }
        }
        .padding(.vertical, FormStyleConstants.searchBarVerticalPadding)
        .padding(.horizontal, FormStyleConstants.searchBarHorizontalPadding)
        .background(
            RoundedRectangle(cornerRadius: FormStyleConstants.searchBarCornerRadius)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal, FormStyleConstants.formLeadingPadding)
        .padding(.vertical, FormStyleConstants.searchBarVerticalPadding)
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

    /// При пустом поиске выбранная модель всегда первая в списке (даже если API
    /// отдаёт её ниже или уже не отдаёт вовсе) — иначе в длинном каталоге до неё
    /// приходится прокручивать. При активном поиске порядок каталога сохраняется.
    private var filteredModels: [String] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.isEmpty else {
            return availableModels.filter { $0.localizedCaseInsensitiveContains(query) }
        }
        guard !selectedModel.isEmpty else { return availableModels }
        return [selectedModel] + availableModels.filter { $0 != selectedModel }
    }
}
