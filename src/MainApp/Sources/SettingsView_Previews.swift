import Common
import SwiftUI

#if DEBUG
    public struct SettingsView_Previews: PreviewProvider {
        public static var previews: some View {
            let viewModel = SettingsViewModel(authManager: AuthManagerMock())
            return SettingsView(viewModel: viewModel)
                .task { await viewModel.load() }
        }
    }
#endif
