/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation
import CommonWallet
import SoraUI

final class SoraActionsCollectionViewCell: UICollectionViewCell {
    @IBOutlet private var sendButton: RoundedButton!
    @IBOutlet private var receiveButton: RoundedButton!
    @IBOutlet private var depositButton: RoundedButton!

    private(set) var actionsViewModel: SoraActionsViewModel?

    override func prepareForReuse() {
        super.prepareForReuse()

        actionsViewModel = nil
    }

    @IBAction private func actionSend() {
        if let actionsViewModel = actionsViewModel {
            try? actionsViewModel.send.command.execute()
        }
    }

    @IBAction private func actionReceive() {
        if let actionsViewModel = actionsViewModel {
            try? actionsViewModel.receive.command.execute()
        }
    }

    @IBAction private func actionDeposition() {
        if let actionsViewModel = actionsViewModel {
            try? actionsViewModel.deposit.command.execute()
        }
    }
}

extension SoraActionsCollectionViewCell: WalletViewProtocol {
    var viewModel: WalletViewModelProtocol? {
        return actionsViewModel
    }

    func bind(viewModel: WalletViewModelProtocol) {
        if let actionsViewModel = viewModel as? SoraActionsViewModel {
            self.actionsViewModel = actionsViewModel

            sendButton.imageWithTitleView?.title = actionsViewModel.send.title
            receiveButton.imageWithTitleView?.title = actionsViewModel.receive.title
            depositButton.imageWithTitleView?.title = actionsViewModel.deposit.title
            sendButton.imageWithTitleView?.titleColor = actionsViewModel.send.style.color
            sendButton.imageWithTitleView?.titleFont = actionsViewModel.send.style.font
            receiveButton.imageWithTitleView?.titleColor = actionsViewModel.receive.style.color
            receiveButton.imageWithTitleView?.titleFont = actionsViewModel.receive.style.font
            depositButton.imageWithTitleView?.titleColor = actionsViewModel.deposit.style.color
            depositButton.imageWithTitleView?.titleFont = actionsViewModel.deposit.style.font

            sendButton.invalidateLayout()
            receiveButton.invalidateLayout()
            depositButton.invalidateLayout()
        }
    }
}
