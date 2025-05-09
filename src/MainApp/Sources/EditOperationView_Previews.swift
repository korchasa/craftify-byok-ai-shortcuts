import SwiftUI

#if DEBUG
    private let previewColorIndex = 2

    public struct EditOperationView_Previews: PreviewProvider {
        public static var previews: some View {
            let params = try! JSONEncoder().encode(TranslateParams(targetLanguage: "en"))
            let operation = InventoryOperation(
                operation: .translate,
                params: params,
                colorHex: EditOperationViewModel(operation: InventoryOperation(operation: .translate, params: params, colorHex: "ef476f")).palette[previewColorIndex]
            )
            let viewModel = EditOperationViewModel(operation: operation)
            return EditOperationView(viewModel: viewModel, onSave: { _ in })
        }
    }
#endif
