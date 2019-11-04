/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation

final class AmountAssembly: AmountAssemblyProtocol {
    
    static func assembleView(with resolver: ResolverProtocol,
                             payload: AmountPayload,
                             shouldPrepareModalPresentation: Bool) -> AmountViewProtocol? {
        do {
            let view = AmountViewController(nibName: "AmountViewController", bundle: Bundle(for: self))

            view.shouldShowModalPresentationItems = shouldPrepareModalPresentation
            view.style = resolver.style
            view.accessoryFactory = AccessoryViewFactory.self

            let coordinator = AmountCoordinator(resolver: resolver)

            let dataProviderFactory = DataProviderFactory(accountSettings: resolver.account,
                                                          cacheFacade: CoreDataCacheFacade.shared,
                                                          networkOperationFactory: resolver.networkOperationFactory)

            let assetSelectionFactory = AssetSelectionFactory(amountFormatter: resolver.amountFormatter)
            let accessoryViewModelFactory = ContactAccessoryViewModelFactory(style: resolver.style.nameIconStyle,
                                                                             radius: AccessoryView.iconRadius)
            let inputValidatorFactory = resolver.inputValidatorFactory
            let transferViewModelFactory = AmountViewModelFactory(amountFormatter: resolver.amountFormatter,
                                                                  amountLimit: resolver.transferAmountLimit,
                                                                  descriptionValidatorFactory: inputValidatorFactory,
                                                                  feeInfoFactory: resolver.feeInfoFactory,
                                                                  assetSelectionFactory: assetSelectionFactory,
                                                                  accessoryFactory: accessoryViewModelFactory)

            let presenter = try  AmountPresenter(view: view,
                                                 coordinator: coordinator,
                                                 payload: payload,
                                                 dataProviderFactory: dataProviderFactory,
                                                 feeCalculationFactory: resolver.feeCalculationFactory,
                                                 account: resolver.account,
                                                 transferViewModelFactory: transferViewModelFactory)
            view.presenter = presenter

            return view
        } catch {
            resolver.logger?.error("Did receive unexpected error \(error)")
            return nil
        }
    }
    
}
