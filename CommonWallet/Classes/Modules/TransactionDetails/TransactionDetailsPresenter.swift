/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation
import IrohaCommunication


final class TransactionDetailsPresenter {
    weak var view: WalletFormViewProtocol?
    var coordinator: TransactionDetailsCoordinatorProtocol

    let resolver: ResolverProtocol
    let configuration: TransactionDetailsConfigurationProtocol
    let transactionData: AssetTransactionData
    let transactionType: WalletTransactionType
    let accessoryViewModelFactory: ContactAccessoryViewModelFactoryProtocol
    let feeInfoFactory: FeeInfoFactoryProtocol

    init(view: WalletFormViewProtocol,
         coordinator: TransactionDetailsCoordinatorProtocol,
         configuration: TransactionDetailsConfigurationProtocol,
         resolver: ResolverProtocol,
         transactionData: AssetTransactionData,
         transactionType: WalletTransactionType,
         accessoryViewModelFactory: ContactAccessoryViewModelFactoryProtocol,
         feeInfoFactory: FeeInfoFactoryProtocol) {
        self.view = view
        self.coordinator = coordinator
        self.configuration = configuration
        self.resolver = resolver
        self.transactionData = transactionData
        self.transactionType = transactionType
        self.accessoryViewModelFactory = accessoryViewModelFactory
        self.feeInfoFactory = feeInfoFactory
    }

    private func createStatusViewModel(for status: AssetTransactionStatus) -> WalletFormViewModel {
        switch status {
        case .commited:
            return WalletFormViewModel(layoutType: .accessory,
                                       title: "Status",
                                       details: "Success",
                                       detailsColor: resolver.style.statusStyleContainer.approved.color,
                                       icon: resolver.style.statusStyleContainer.approved.icon)
        case .pending:
            return WalletFormViewModel(layoutType: .accessory,
                                       title: "Status",
                                       details: "Pending",
                                       detailsColor: resolver.style.statusStyleContainer.pending.color,
                                       icon: resolver.style.statusStyleContainer.pending.icon)
        case .rejected:
            return WalletFormViewModel(layoutType: .accessory,
                                       title: "Status",
                                       details: "Rejected",
                                       detailsColor: resolver.style.statusStyleContainer.rejected.color,
                                       icon: resolver.style.statusStyleContainer.rejected.icon)
        }
    }

    private func createSigleAmountViewModel(for amount: Decimal, title: String, hasIcon: Bool) -> WalletFormViewModel {
        let asset = resolver.account.assets.first {
            $0.identifier.identifier() == transactionData.assetId
        }

        let assetSymbol = asset?.symbol ?? ""
        let amountString = resolver.amountFormatter.string(from: amount as NSNumber) ?? ""

        let details = assetSymbol + amountString

        var icon: UIImage?

        if hasIcon {
            icon = transactionType.isIncome ? resolver.style.amountChangeStyle.increase
                : resolver.style.amountChangeStyle.decrease
        }

        return WalletFormViewModel(layoutType: .accessory,
                                   title: title,
                                   details: details,
                                   icon: icon)
    }

    private func createFeeViewModel(for fee: AssetAmountData, hasIcon: Bool) -> WalletFormViewModel? {
        guard let amount = fee.decimalAmount else {
            return nil
        }

        guard let sourceAsset = resolver.account.assets
            .first(where: { $0.identifier.identifier() == transactionData.assetId}) else {
            return nil
        }

        guard let feeAsset = resolver.account.assets
            .first(where: { $0.identifier.identifier() == fee.assetId }) else {
            return nil
        }

        guard let title = feeInfoFactory.createTransactionDetailsTitle(for: transactionType,
                                                                       sourceAsset: sourceAsset,
                                                                       feeAsset: feeAsset) else {
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

    private func createTotal(for amount: Decimal, fees: [AssetAmountData]) -> [WalletFormViewModel] {
        var viewModels: [WalletFormViewModel] = []

        let amountViewModel = createSigleAmountViewModel(for: amount, title: "Amount sent", hasIcon: false)

        viewModels.append(amountViewModel)

        let feeViewModels = fees.compactMap { fee in
            return createFeeViewModel(for: fee, hasIcon: false)
        }

        viewModels.append(contentsOf: feeViewModels)

        let totalAmount: Decimal = fees.reduce(amount) { (result, fee) in
            guard let decimalFee = fee.decimalAmount else {
                return result
            }

            return result + decimalFee
        }

        let totalAmountViewModel = createSigleAmountViewModel(for: totalAmount,
                                                              title: "Total amount",
                                                              hasIcon: true)

        viewModels.append(totalAmountViewModel)

        return viewModels
    }

    private func createAmountViewModels() -> [WalletFormViewModel] {
        guard let amount = Decimal(string: transactionData.amount) else {
            return []
        }

        let singleAmountTitle = "Amount"

        guard !transactionType.isIncome, let fees = transactionData.fees, fees.count > 0 else {
            let singleAmountViewModel = createSigleAmountViewModel(for: amount,
                                                                   title: singleAmountTitle,
                                                                   hasIcon: true)
            return [singleAmountViewModel]
        }

        let amountFees = fees.filter { $0.assetId == transactionData.assetId }
        let otherFees = fees.filter { $0.assetId != transactionData.assetId }

        var viewModels: [WalletFormViewModel] = []

        if amountFees.count > 0 {
            let totalViewModels = createTotal(for: amount, fees: amountFees)
            viewModels.append(contentsOf: totalViewModels)
        } else {
            let singleViewModel = createSigleAmountViewModel(for: amount, title: singleAmountTitle, hasIcon: true)
            viewModels.append(singleViewModel)
        }

        let otherViewModels = otherFees.compactMap { fee in
            return createFeeViewModel(for: fee, hasIcon: true)
        }

        viewModels.append(contentsOf: otherViewModels)

        return viewModels
    }

    private func createAccessoryViewModel() -> AccessoryViewModel {
        let nameComponents = transactionData.peerName.components(separatedBy: " ")
        let firstName = nameComponents.first ?? ""
        let lastName = nameComponents.last ?? ""

        return accessoryViewModelFactory.createViewModel(from: transactionData.peerName,
                                                         firstName: firstName,
                                                         lastName: lastName,
                                                         action: "Send back")
    }

    private func createPeerViewModel() -> WalletFormViewModel? {
        if transactionType.backendName == WalletTransactionType.incoming.backendName {
            return WalletFormViewModel(layoutType: .accessory,
                                       title: "Sender",
                                       details: transactionData.peerName)
        }

        if transactionType.backendName == WalletTransactionType.outgoing.backendName {
            return WalletFormViewModel(layoutType: .accessory,
                                       title: "Recipient",
                                       details: transactionData.peerName)
        }

        return nil
    }

    private func updateView() {
        var viewModels = [WalletFormViewModel]()

        let idViewModel = WalletFormViewModel(layoutType: .accessory,
                                              title: "Identifier",
                                              details: transactionData.displayIdentifier)
        viewModels.append(idViewModel)

        let statusViewModel: WalletFormViewModel = createStatusViewModel(for: transactionData.status)
        viewModels.append(statusViewModel)

        if transactionData.status == .rejected, let reason = transactionData.reason, !reason.isEmpty {
            let reasonViewModel = WalletFormViewModel(layoutType: .details,
                                                      title: "Reason",
                                                      details: reason)
            viewModels.append(reasonViewModel)
        }

        let transactionDate = Date(timeIntervalSince1970: TimeInterval(transactionData.timestamp))
        let timeViewModel = WalletFormViewModel(layoutType: .accessory,
                                                title: "Date and Time",
                                                details: resolver.statusDateFormatter.string(from: transactionDate))
        viewModels.append(timeViewModel)

        if !transactionType.displayName.isEmpty {
            let typeViewModel = WalletFormViewModel(layoutType: .accessory,
                                                    title: "Type",
                                                    details: transactionType.displayName)
            viewModels.append(typeViewModel)
        }

        if let peerViewModel = createPeerViewModel() {
            viewModels.append(peerViewModel)
        }

        viewModels.append(contentsOf: createAmountViewModels())

        if !transactionData.details.isEmpty {
            let descriptionViewModel = WalletFormViewModel(layoutType: .details,
                                                           title: "Description",
                                                           details: transactionData.details)

            viewModels.append(descriptionViewModel)
        }

        view?.didReceive(viewModels: viewModels)

        if transactionType.isIncome,
            configuration.sendBackTransactionTypes.contains(transactionType.backendName) {
            let accessoryViewModel = createAccessoryViewModel()
            view?.didReceive(accessoryViewModel: accessoryViewModel)
        }
    }
}


extension TransactionDetailsPresenter: TransactionDetailsPresenterProtocol {
    func setup() {
        updateView()
    }

    func performAction() {
        guard
            let accountId = try? IRAccountIdFactory.account(withIdentifier: transactionData.peerId),
            let assetId = try? IRAssetIdFactory.asset(withIdentifier: transactionData.assetId) else {
            return
        }

        let receiverInfo = ReceiveInfo(accountId: accountId,
                                       assetId: assetId,
                                       amount: nil,
                                       details: nil)

        let payload = AmountPayload(receiveInfo: receiverInfo,
                                    receiverName: transactionData.peerName)

        coordinator.send(to: payload)
    }
}
