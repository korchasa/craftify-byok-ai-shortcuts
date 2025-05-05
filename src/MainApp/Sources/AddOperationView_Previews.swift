import SwiftUI

#if DEBUG
    private let previewColorIndex = 2

    public struct AddOperationView_Previews: PreviewProvider {
        public static var previews: some View {
            let viewModel = AddOperationViewModel()
            viewModel.selectedKind = .translate
            viewModel.targetLanguage = "en"
            viewModel.selectedColorHex = AddOperationViewModel.palette[previewColorIndex]
            return AddOperationView(viewModel: viewModel)
        }
    }
#endif
