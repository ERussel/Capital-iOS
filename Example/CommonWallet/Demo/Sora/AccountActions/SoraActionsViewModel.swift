/**
 * Copyright Soramitsu Co., Ltd. All Rights Reserved.
 * SPDX-License-Identifier: GPL-3.0
 */

import Foundation
import CommonWallet

final class SoraActionsViewModel: ActionsViewModelProtocol {
    var cellReuseIdentifier: String
    var itemHeight: CGFloat

    var command: WalletCommandProtocol? { return nil }

    var send: ActionViewModelProtocol
    var receive: ActionViewModelProtocol
    var deposit: ActionViewModelProtocol

    init(cellReuseIdentifier: String,
         itemHeight: CGFloat,
         sendViewModel: ActionViewModelProtocol,
         receiveViewModel: ActionViewModelProtocol,
         depositViewModel: ActionViewModelProtocol) {
        self.cellReuseIdentifier = cellReuseIdentifier
        self.itemHeight = itemHeight
        self.send = sendViewModel
        self.receive = receiveViewModel
        self.deposit = depositViewModel
    }
}
