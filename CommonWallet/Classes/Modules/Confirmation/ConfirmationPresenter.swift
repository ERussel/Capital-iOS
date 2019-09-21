/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation
import IrohaCommunication
import RobinHood


final class ConfirmationPresenter {
    weak var view: WalletFormViewProtocol?
    var coordinator: ConfirmationCoordinatorProtocol

    let payload: TransferPayload
    let service: WalletServiceProtocol
    let resolver: ResolverProtocol
    let accessoryViewModelFactory: ContactAccessoryViewModelFactoryProtocol
    let eventCenter: WalletEventCenterProtocol
    let feeInfoFactory: FeeInfoFactoryProtocol

    var logger: WalletLoggerProtocol?

    init(view: WalletFormViewProtocol,
         coordinator: ConfirmationCoordinatorProtocol,
         service: WalletServiceProtocol,
         resolver: ResolverProtocol,
         payload: TransferPayload,
         eventCenter: WalletEventCenterProtocol,
         feeInfoFactory: FeeInfoFactoryProtocol,
         accessoryViewModelFactory: ContactAccessoryViewModelFactoryProtocol) {
        self.view = view
        self.coordinator = coordinator
        self.service = service
        self.payload = payload
        self.resolver = resolver
        self.feeInfoFactory = feeInfoFactory
        self.accessoryViewModelFactory = accessoryViewModelFactory
        self.eventCenter = eventCenter
    }

    private func handleTransfer(result: Result<Void, Error>) {
        switch result {
        case .success:
            eventCenter.notify(with: TransferCompleteEvent(payload: payload))
            
            coordinator.showResult(payload: payload)
        case .failure:
            view?.showError(message: "Transaction failed. Please, try again later.")
        }
    }

    private func prepareSigleAmountViewModel(for amount: Decimal, title: String, hasIcon: Bool) -> WalletFormViewModel {
        let asset = resolver.account.assets.first {
            $0.identifier.identifier() == payload.transferInfo.asset.identifier()
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
            .first(where: { $0.identifier.identifier() == payload.transferInfo.asset.identifier() }) else {
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

    private func prepareAmountViewModels(for amount: Decimal, fees: [FeeInfo]) -> [WalletFormViewModel] {
        var viewModels: [WalletFormViewModel] = []

        let mainFees = fees.filter { $0.assetId.identifier() == payload.transferInfo.asset.identifier() }
        let otherFees = fees.filter { $0.assetId.identifier() != payload.transferInfo.asset.identifier() }

        if mainFees.count > 0 {
            let amountViewModel = prepareSigleAmountViewModel(for: amount, title: "Amount to send", hasIcon: false)
            viewModels.append(amountViewModel)

            let mainFeeViewModels = mainFees.compactMap { fee in
                return prepareFeeViewModel(for: fee, hasIcon: false)
            }

            viewModels.append(contentsOf: mainFeeViewModels)

            let totalAmount: Decimal = mainFees.reduce(amount) { (result, fee) in
                guard let decimalFee = Decimal(string: fee.amount.value) else {
                    return result
                }

                return result + decimalFee
            }

            let totalAmountViewModel = prepareSigleAmountViewModel(for: totalAmount,
                                                                   title: "Total amount",
                                                                   hasIcon: true)

            viewModels.append(totalAmountViewModel)
        } else {
            let amountViewModel = prepareSigleAmountViewModel(for: amount, title: "Amount", hasIcon: true)
            viewModels.append(amountViewModel)
        }

        let otherFeeViewModels = otherFees.compactMap { fee in
            return prepareFeeViewModel(for: fee, hasIcon: true)
        }

        viewModels.append(contentsOf: otherFeeViewModels)

        return viewModels
    }

    func provideMainViewModels() {
        var viewModels: [WalletFormViewModel] = []

        viewModels.append(WalletFormViewModel(layoutType: .accessory,
                                              title: "Please check and confirm details",
                                              details: nil))

        if let decimalAmount = Decimal(string: payload.transferInfo.amount.value) {
            let amountViewModels = prepareAmountViewModels(for: decimalAmount,
                                                           fees: payload.transferInfo.fees)

            viewModels.append(contentsOf: amountViewModels)
        }

        if !payload.transferInfo.details.isEmpty {
            viewModels.append(WalletFormViewModel(layoutType: .details,
                                                  title: "Description",
                                                  details: payload.transferInfo.details))
        }

        view?.didReceive(viewModels: viewModels)
    }

    func provideAccessoryViewModel() {
        let viewModel = accessoryViewModelFactory.createViewModel(from: payload.receiverName,
                                                                  fullName: payload.receiverName,
                                                                  action: "Send")
        view?.didReceive(accessoryViewModel: viewModel)
    }
}


extension ConfirmationPresenter: ConfirmationPresenterProtocol {
    
    func setup() {
        provideMainViewModels()
        provideAccessoryViewModel()
    }
    
    func performAction() {
        view?.didStartLoading()

        service.transfer(info: payload.transferInfo, runCompletionIn: .main) { [weak self] (optionalResult) in
            self?.view?.didStopLoading()

            if let result = optionalResult {
                self?.handleTransfer(result: result)
            }
        }
    }
}
