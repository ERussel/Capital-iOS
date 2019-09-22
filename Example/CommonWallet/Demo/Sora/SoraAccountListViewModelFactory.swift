import Foundation
import CommonWallet
import IrohaCommunication

final class SoraAccountListViewModelFactory: AccountListViewModelFactoryProtocol {
    let actionsViewModel: ActionsViewModelProtocol

    init(actionsViewModel: ActionsViewModelProtocol) {
        self.actionsViewModel = actionsViewModel
    }

    func createActionsViewModel(for assetId: IRAssetId?,
                                commandFactory: WalletCommandFactoryProtocol) -> ActionsViewModelProtocol? {
        return actionsViewModel
    }
}