/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation

final class WithdrawResultPresenter {
    weak var view: WalletFormViewProtocol?
    var coordinator: WithdrawResultCoordinatorProtocol

    let withdrawInfo: WithdrawInfo
    let asset: WalletAsset
    let assets: [WalletAsset]
    let withdrawOption: WalletWithdrawOption
    let style: WalletStyleProtocol
    let amountFormatter: NumberFormatter
    let dateFormatter: DateFormatter
    let feeInfoFactory: FeeInfoFactoryProtocol

    init(view: WalletFormViewProtocol,
         coordinator: WithdrawResultCoordinatorProtocol,
         withdrawInfo: WithdrawInfo,
         asset: WalletAsset,
         assets: [WalletAsset],
         withdrawOption: WalletWithdrawOption,
         style: WalletStyleProtocol,
         amountFormatter: NumberFormatter,
         dateFormatter: DateFormatter,
         feeInfoFactory: FeeInfoFactoryProtocol) {
        self.view = view
        self.coordinator = coordinator
        self.withdrawInfo = withdrawInfo
        self.asset = asset
        self.assets = assets
        self.style = style
        self.withdrawOption = withdrawOption
        self.amountFormatter = amountFormatter
        self.dateFormatter = dateFormatter
        self.feeInfoFactory = feeInfoFactory
    }

    private func prepareSigleAmountViewModel(for amount: Decimal, title: String, hasIcon: Bool) -> WalletFormViewModel {
        let amountString = amountFormatter.string(from: amount as NSNumber) ?? ""

        let details = asset.symbol + amountString

        var icon: UIImage?

        if hasIcon {
            icon = style.amountChangeStyle.decrease
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

        guard let sourceAsset = assets
            .first(where: { $0.identifier.identifier() == withdrawInfo.assetId.identifier() }) else {
            return nil
        }

        guard let feeAsset = assets.first(where: { $0.identifier.identifier() == fee.assetId.identifier() }) else {
            return nil
        }

        guard let title = feeInfoFactory.createWithdrawAmountTitle(for: sourceAsset,
                                                                   feeAsset: feeAsset,
                                                                   option: withdrawOption) else {
            return nil
        }

        guard let amountString = amountFormatter.string(from: amount as NSNumber) else {
            return nil
        }

        let details = feeAsset.symbol + amountString

        let icon: UIImage? = hasIcon ? style.amountChangeStyle.decrease : nil

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

    private func createDescriptionViewModel() -> WalletFormViewModelProtocol? {
        guard !withdrawInfo.details.isEmpty else {
            return nil
        }

        return WalletFormViewModel(layoutType: .details,
                                   title: withdrawOption.details,
                                   details: withdrawInfo.details)
    }

    private func provideFormViewModels() {
        var viewModels: [WalletFormViewModelProtocol] = []

        let statusViewModel = WalletFormViewModel(layoutType: .accessory,
                                                  title: "Status",
                                                  details: "Pending",
                                                  icon: style.statusStyleContainer.pending.icon)
        viewModels.append(statusViewModel)

        let timeViewModel = WalletFormViewModel(layoutType: .accessory,
                                                title: "Date and Time",
                                                details: dateFormatter.string(from: Date()))
        viewModels.append(timeViewModel)

        if let decimalAmount = Decimal(string: withdrawInfo.amount.value) {
            let amountViewModels = prepareTotal(for: decimalAmount, fees: withdrawInfo.fees)
            viewModels.append(contentsOf: amountViewModels)
        }

        if let descriptionViewModel = createDescriptionViewModel() {
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


extension WithdrawResultPresenter: WithdrawResultPresenterProtocol {
    func setup() {
        provideFormViewModels()
        provideAccessoryViewModel()
    }

    func performAction() {
        coordinator.dismiss()
    }
}
