/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation
import RobinHood

final class WithdrawConfirmationPresenter {
    weak var view: WalletFormViewProtocol?
    var coordinator: WithdrawConfirmationCoordinatorProtocol

    let walletService: WalletServiceProtocol
    let withdrawInfo: WithdrawInfo
    let asset: WalletAsset
    let assets: [WalletAsset]
    let withdrawOption: WalletWithdrawOption
    let style: WalletStyleProtocol
    let amountFormatter: NumberFormatter
    let eventCenter: WalletEventCenterProtocol
    let feeInfoFactory: FeeInfoFactoryProtocol

    init(view: WalletFormViewProtocol,
         coordinator: WithdrawConfirmationCoordinatorProtocol,
         walletService: WalletServiceProtocol,
         withdrawInfo: WithdrawInfo,
         asset: WalletAsset,
         assets: [WalletAsset],
         withdrawOption: WalletWithdrawOption,
         style: WalletStyleProtocol,
         amountFormatter: NumberFormatter,
         eventCenter: WalletEventCenterProtocol,
         feeInfoFactory: FeeInfoFactoryProtocol) {
        self.view = view
        self.coordinator = coordinator
        self.walletService = walletService
        self.withdrawInfo = withdrawInfo
        self.asset = asset
        self.assets = assets
        self.withdrawOption = withdrawOption
        self.style = style
        self.amountFormatter = amountFormatter
        self.eventCenter = eventCenter
        self.feeInfoFactory = feeInfoFactory
    }

    private func prepareSingleAmountViewModel(for amount: Decimal, title: String, hasIcon: Bool) -> WalletFormViewModel {
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

        guard let title = feeInfoFactory
            .createWithdrawAmountTitle(for: sourceAsset, feeAsset: feeAsset, option: withdrawOption) else {
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

    private func prepareAmountViewModels(for amount: Decimal, fees: [FeeInfo]) -> [WalletFormViewModel] {
        var viewModels: [WalletFormViewModel] = []

        let mainFees = fees.filter { $0.assetId.identifier() == withdrawInfo.assetId.identifier() }
        let otherFees = fees.filter { $0.assetId.identifier() != withdrawInfo.assetId.identifier() }

        if mainFees.count > 0 {
            let amountViewModel = prepareSingleAmountViewModel(for: amount, title: "Amount to send", hasIcon: false)
            viewModels.append(amountViewModel)

            let mainFeeViewModels = mainFees.compactMap { fee in
                return prepareFeeViewModel(for: fee, hasIcon: false)
            }

            viewModels.append(contentsOf: mainFeeViewModels)
        } else {
            let amountViewModel = prepareSingleAmountViewModel(for: amount, title: "Amount", hasIcon: true)
            viewModels.append(amountViewModel)
        }

        let otherFeeViewModels = otherFees.compactMap { fee in
            return prepareFeeViewModel(for: fee, hasIcon: true)
        }

        viewModels.append(contentsOf: otherFeeViewModels)

        return viewModels
    }

    private func prepareDescriptionViewModel() -> WalletFormViewModelProtocol? {
        guard !withdrawInfo.details.isEmpty else {
            return nil
        }

        return WalletFormViewModel(layoutType: .details,
                                   title: withdrawOption.details,
                                   details: withdrawInfo.details)
    }

    private func createAccessoryViewModel() -> AccessoryViewModelProtocol {
        let accessoryViewModel = AccessoryViewModel(title: "", action: "Withdraw")

        guard let amountDecimal = Decimal(string: withdrawInfo.amount.value) else {
            return accessoryViewModel
        }

        let mainFees = withdrawInfo.fees.filter( { $0.assetId.identifier() == asset.identifier.identifier() })

        let totalAmount = mainFees.reduce(amountDecimal) { (result, fee) in
            guard let decimalFee = Decimal(string: fee.amount.value) else {
                return result
            }

            return result + decimalFee
        }

        guard let totalAmountString = amountFormatter.string(from: totalAmount as NSNumber) else {
            return accessoryViewModel
        }

        accessoryViewModel.title = "Total amount \(asset.symbol)\(totalAmountString)"
        accessoryViewModel.numberOfLines = 2

        return accessoryViewModel
    }

    private func updateView() {
        var viewModels: [WalletFormViewModelProtocol] = []

        let titleViewModel = WalletFormViewModel(layoutType: .accessory,
                                                 title: "Please check and confirm details",
                                                 details: nil)
        viewModels.append(titleViewModel)

        if let decimalAmount = Decimal(string: withdrawInfo.amount.value) {
            let amountViewModels = prepareAmountViewModels(for: decimalAmount, fees: withdrawInfo.fees)
            viewModels.append(contentsOf: amountViewModels)
        }

        if let descriptionViewModel = prepareDescriptionViewModel() {
            viewModels.append(descriptionViewModel)
        }

        view?.didReceive(viewModels: viewModels)

        let accesoryViewModel = prepareAccessoryViewModel()
        view?.didReceive(accessoryViewModel: accesoryViewModel)
    }

    private func handleWithdraw(result: Result<Void, Error>) {
        switch result {
        case .success:
            eventCenter.notify(with: WithdrawCompleteEvent(withdrawInfo: withdrawInfo))

            coordinator.showResult(for: withdrawInfo, asset: asset, option: withdrawOption)
        case .failure:
            view?.showError(message: "Withdraw failed. Please, try again later.")
        }
    }
}


extension WithdrawConfirmationPresenter: WithdrawConfirmationPresenterProtocol {
    func setup() {
        updateView()
    }

    func performAction() {
        view?.didStartLoading()

        walletService.withdraw(info: withdrawInfo, runCompletionIn: .main) { [weak self] result in
            self?.view?.didStopLoading()

            if let result = result {
                self?.handleWithdraw(result: result)
            }
        }
    }
}
