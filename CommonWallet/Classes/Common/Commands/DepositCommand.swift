/**
 * Copyright Soramitsu Co., Ltd. All Rights Reserved.
 * SPDX-License-Identifier: GPL-3.0
 */

import Foundation
import IrohaCommunication

final class DepositCommand {
    let resolver: ResolverProtocol

    var presentationStyle: WalletPresentationStyle = .modal(inNavigation: true)

    init(resolver: ResolverProtocol) {
        self.resolver = resolver
    }
}

extension DepositCommand: WalletPresentationCommandProtocol {
    func execute() throws {
        guard
            let depositView = DepositAssembly.assembleView(resolver: resolver),
            let navigation = resolver.navigation  else {
                return
        }

        present(view: depositView.controller, in: navigation)
    }
}
