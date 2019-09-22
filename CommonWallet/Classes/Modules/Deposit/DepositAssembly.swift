/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation

final class DepositAssembly: DepositAssemblyProtocol {
    static func assembleView(resolver: ResolverProtocol) -> DepositViewProtocol? {
        guard let selectedAsset = resolver.account.assets.first else {
            resolver.logger?.error("No assets found")
            return nil
        }

        guard let viewModelFactory = resolver.depositConfiguration?.viewModelFactory else {
            resolver.logger?.error("No deposit view model factory found")
            return nil
        }

        let view = DepositViewController(nibName: "DepositViewController", bundle: Bundle(for: self))
        view.style = resolver.style

        let coordinator = DepositCoordinator(resolver: resolver)

        let qrService = WalletQRService(operationFactory: WalletQROperationFactory())
        let assetSelectionFactory = AssetSelectionFactory(amountFormatter: resolver.amountFormatter)

        let presenter = DepositPresenter(view: view,
                                         coordinator: coordinator,
                                         account: resolver.account,
                                         depositViewModelFactory: viewModelFactory,
                                         assetSelectionFactory: assetSelectionFactory,
                                         qrService: qrService,
                                         selectedAsset: selectedAsset)

        view.presenter = presenter

        return view
    }
}
