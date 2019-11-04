/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation


final class ConfirmationAssembly: ConfirmationAssemblyProtocol {
    
    static func assembleView(with resolver: ResolverProtocol, payload: TransferPayload) -> WalletFormViewProtocol? {
        let view = WalletFormViewController(nibName: "WalletFormViewController", bundle: Bundle(for: self))
        view.loadingViewFactory = WalletLoadingOverlayFactory(style: resolver.style.loadingOverlayStyle)
        view.accessoryViewFactory = AccessoryViewFactory.self
        view.style = resolver.style
        view.title = "Confirmation"
        
        let coordinator = ConfirmationCoordinator(resolver: resolver)
        
        let walletService = WalletService(operationFactory: resolver.networkOperationFactory)

        let accessoryViewModelFactory = ContactAccessoryViewModelFactory(style: resolver.style.nameIconStyle,
                                                                         radius: AccessoryView.iconRadius)

        let presenter = ConfirmationPresenter(view: view,
                                              coordinator: coordinator,
                                              service: walletService,
                                              resolver: resolver,
                                              payload: payload,
                                              eventCenter: resolver.eventCenter,
                                              feeInfoFactory: resolver.feeInfoFactory,
                                              accessoryViewModelFactory: accessoryViewModelFactory)

        presenter.logger = resolver.logger

        view.presenter = presenter

        return view
    }
    
}
