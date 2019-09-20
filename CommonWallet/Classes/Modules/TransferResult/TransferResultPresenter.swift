/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation
import RobinHood


final class TransferResultPresenter {

    weak var view: WalletFormViewProtocol?
    var coordinator: TransferResultCoordinatorProtocol

    let transferPayload: TransferPayload
    let resolver: ResolverProtocol
    let feeInfoFactory: FeeInfoFactoryProtocol

    init(view: WalletFormViewProtocol,
         coordinator: TransferResultCoordinatorProtocol,
         payload: TransferPayload,
         resolver: ResolverProtocol,
         feeInfoFactory: FeeInfoFactoryProtocol) {
        self.view = view
        self.coordinator = coordinator
        self.resolver = resolver
        self.transferPayload = payload
        self.feeInfoFactory = feeInfoFactory
    }

    private func prepareSigleAmountViewModel(for amount: Decimal, title: String, hasIcon: Bool) -> WalletFormViewModel {
        let asset = resolver.account.assets.first {
            $0.identifier.identifier() == transferPayload.transferInfo.asset.identifier()
        }

        let assetSymbol = asset?.symbol ?? ""
        let amountString = resolver.amountFormatter.string(from: amount as NSNumber) ?? ""

        let details = assetSymbol + amountString

        var icon: UIImage?

        if hasIcon {
            icon = resolver.style.amountChangeStyle.decrease
        }

        return WalletFormViewModel(layoutType: .accessory,
                                   title: title,
                                   details: details,
                                   icon: icon)
    }

    private func prepareFeeViewModel(for fee: FeeInfo, hasIcon: Bool) -> WalletFormViewModel? {
        guard let amount = Decimal(string: fee.amount.value) else {
            return nil
        }

        guard let sourceAsset = resolver.account.assets
            .first(where: { $0.identifier.identifier() == transferPayload.transferInfo.asset.identifier() }) else {
                return nil
        }

        guard let feeAsset = resolver.account.assets
            .first(where: { $0.identifier.identifier() == fee.assetId.identifier() }) else {
                return nil
        }

        guard let title = feeInfoFactory.createTransferAmountTitle(for: sourceAsset, feeAsset: feeAsset) else {
            return nil
        }

        guard let amountString = resolver.amountFormatter.string(from: amount as NSNumber) else {
            return nil
        }

        let details = feeAsset.symbol + amountString

        let icon: UIImage? = hasIcon ? resolver.style.amountChangeStyle.decrease : nil

        return WalletFormViewModel(layoutType: .accessory,
                                   title: title,
                                   details: details,
                                   icon: icon)
    }

    private func prepareTotal(for amount: Decimal, fees: [FeeInfo]) -> [WalletFormViewModel] {
        var viewModels: [WalletFormViewModel] = []

        let amountViewModel = prepareSigleAmountViewModel(for: amount, title: "Amount sent", hasIcon: false)

        viewModels.append(amountViewModel)

        let feeViewModels = fees.compactMap { fee in
            return prepareFeeViewModel(for: fee, hasIcon: false)
        }

        viewModels.append(contentsOf: feeViewModels)

        let totalAmount: Decimal = fees.reduce(amount) { (result, fee) in
            guard let decimalFee = Decimal(string: fee.amount.value) else {
                return result
            }

            return result + decimalFee
        }

        let totalAmountViewModel = prepareSigleAmountViewModel(for: totalAmount,
                                                               title: "Total amount",
                                                               hasIcon: true)

        viewModels.append(totalAmountViewModel)

        return viewModels
    }


    private func provideMainViewModels() {
        let statusViewModel = WalletFormViewModel(layoutType: .accessory,
                                                  title: "Status",
                                                  details: "Pending",
                                                  icon: resolver.style.statusStyleContainer.pending.icon)
        let timeViewModel = WalletFormViewModel(layoutType: .accessory,
                                                title: "Date and Time",
                                                details: resolver.statusDateFormatter.string(from: Date()))
        let receiverViewModel = WalletFormViewModel(layoutType: .accessory,
                                                    title: "Recipient",
                                                    details: transferPayload.receiverName)

        var viewModels = [statusViewModel, timeViewModel, receiverViewModel]

        if let decimalAmount = Decimal(string: transferPayload.transferInfo.amount.value) {
            let amountViewModels = prepareTotal(for: decimalAmount, fees: transferPayload.transferInfo.fees)
            viewModels.append(contentsOf: amountViewModels)
        }

        if !transferPayload.transferInfo.details.isEmpty {
            let descriptionViewModel = WalletFormViewModel(layoutType: .details,
                                                           title: "Description",
                                                           details: transferPayload.transferInfo.details)

            viewModels.append(descriptionViewModel)
        }

        view?.didReceive(viewModels: viewModels)
    }

    private func provideAccessoryViewModel() {
        let viewModel = AccessoryViewModel(title: "Funds are being sent",
                                           action: "Done")
        view?.didReceive(accessoryViewModel: viewModel)
    }
}


extension TransferResultPresenter: TransferResultPresenterProtocol {
    func setup() {
        provideMainViewModels()
        provideAccessoryViewModel()
    }

    func performAction() {
        coordinator.dismiss()
    }
}
