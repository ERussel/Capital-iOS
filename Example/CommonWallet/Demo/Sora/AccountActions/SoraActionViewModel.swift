/**
 * Copyright Soramitsu Co., Ltd. All Rights Reserved.
 * SPDX-License-Identifier: GPL-3.0
 */

import Foundation
import CommonWallet

final class SoraActionViewModel {
    let title: String
    let style: WalletTextStyleProtocol

    var underlyingCommand: WalletCommandProtocol?

    init(title: String, style: WalletTextStyle) {
        self.title = title
        self.style = style
    }
}

extension SoraActionViewModel: ActionViewModelProtocol {
    var command: WalletCommandProtocol {
        return underlyingCommand!
    }
}
