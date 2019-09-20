/**
 * Copyright Soramitsu Co., Ltd. All Rights Reserved.
 * SPDX-License-Identifier: GPL-3.0
 */

import Foundation
import RobinHood
import IrohaCommunication

struct WithdrawCheckingState: OptionSet {
    typealias RawValue = UInt8

    static let waiting = WithdrawCheckingState(rawValue: 0)
    static let requestedAmount = WithdrawCheckingState(rawValue: 1)
    static let requestedFee = WithdrawCheckingState(rawValue: 2)
    static let completed = WithdrawCheckingState.requestedAmount.union(.requestedFee)

    var rawValue: WithdrawCheckingState.RawValue

    init(rawValue: WithdrawCheckingState.RawValue) {
        self.rawValue = rawValue
    }
}

final class WithdrawAmountPresenter {

    weak var view: WithdrawAmountViewProtocol?
    var coordinator: WithdrawAmountCoordinatorProtocol
    var logger: WalletLoggerProtocol?

    private var assetSelectionViewModel: AssetSelectionViewModel
    private var amountInputViewModel: AmountInputViewModel
    private var descriptionInputViewModel: DescriptionInputViewModel
    private var feeViewModel: FeeViewModel

    private var balances: [BalanceData]?
    private var metadata: WithdrawMetaData?
    private let dataProviderFactory: DataProviderFactoryProtocol
    private let balanceDataProvider: SingleValueProvider<[BalanceData]>
    private var metaDataProvider: SingleValueProvider<WithdrawMetaData>
    private let assetTitleFactory: AssetSelectionFactoryProtocol
    private let withdrawViewModelFactory: WithdrawAmountViewModelFactoryProtocol
    private let feeCalculationFactory: FeeCalculationFactoryProtocol
    private let assets: [WalletAsset]

    private(set) var selectedAsset: WalletAsset
    private(set) var selectedOption: WalletWithdrawOption

    private(set) var confirmationState: WithdrawCheckingState?

    init(view: WithdrawAmountViewProtocol,
         coordinator: WithdrawAmountCoordinatorProtocol,
         assets: [WalletAsset],
         selectedAsset: WalletAsset,
         selectedOption: WalletWithdrawOption,
         dataProviderFactory: DataProviderFactoryProtocol,
         feeCalculationFactory: FeeCalculationFactoryProtocol,
         withdrawViewModelFactory: WithdrawAmountViewModelFactoryProtocol) throws {

        self.view = view
        self.coordinator = coordinator
        self.selectedAsset = selectedAsset
        self.selectedOption = selectedOption
        self.assets = assets
        self.balanceDataProvider = try dataProviderFactory.createBalanceDataProvider()
        self.metaDataProvider = try dataProviderFactory
            .createWithdrawMetadataProvider(for: selectedAsset.identifier, option: selectedOption.identifier)
        self.dataProviderFactory = dataProviderFactory
        self.withdrawViewModelFactory = withdrawViewModelFactory
        self.feeCalculationFactory = feeCalculationFactory

        descriptionInputViewModel = try withdrawViewModelFactory.createDescriptionViewModel()

        assetSelectionViewModel = withdrawViewModelFactory.createAssetSelectionViewModel(for: selectedAsset,
                                                                                         balance: nil)
        assetSelectionViewModel.canSelect = assets.count > 1

        amountInputViewModel = withdrawViewModelFactory.createAmountViewModel()

        feeViewModel = withdrawViewModelFactory.createMainFeeViewModel(for: selectedAsset, amount: nil)
        feeViewModel.isLoading = true
    }

    private func updateAmountViewModels() {
        guard let amount = amountInputViewModel.decimalAmount, let metadata = metadata else {
            feeViewModel.title = withdrawViewModelFactory.createFeeTitle(for: selectedAsset,
                                                                         feeAsset: selectedAsset,
                                                                         amount: nil)
            feeViewModel.isLoading = true

            let accessoryViewModel = withdrawViewModelFactory.createAccessoryViewModel(for: selectedAsset,
                                                                                       totalAmount: nil)
            view?.didChange(accessoryViewModel: accessoryViewModel)
            return
        }

        guard let fee = metadata.fees.first(where: { $0.assetId == selectedAsset.identifier.identifier() }) else {
            feeViewModel.title = withdrawViewModelFactory.createFeeTitle(for: selectedAsset,
                                                                         feeAsset: selectedAsset,
                                                                         amount: 0.0)
            feeViewModel.isLoading = false

            let accessoryViewModel = withdrawViewModelFactory.createAccessoryViewModel(for: selectedAsset,
                                                                                       totalAmount: nil)
            view?.didChange(accessoryViewModel: accessoryViewModel)

            return
        }

        guard let feeAmount = try? calculateFee(for: feeCalculationFactory,
                                                sourceAsset: selectedAsset,
                                                fee: fee,
                                                amount: amount) else {
            feeViewModel.title = withdrawViewModelFactory.createFeeTitle(for: selectedAsset,
                                                                         feeAsset: selectedAsset,
                                                                         amount: nil)
            feeViewModel.isLoading = true

            let accessoryViewModel = withdrawViewModelFactory.createAccessoryViewModel(for: selectedAsset,
                                                                                       totalAmount: nil)
            view?.didChange(accessoryViewModel: accessoryViewModel)

            return
        }

        feeViewModel.title = withdrawViewModelFactory.createFeeTitle(for: selectedAsset,
                                                                     feeAsset: selectedAsset,
                                                                     amount: feeAmount)
        feeViewModel.isLoading = false

        let totalAmount = amount + feeAmount
        let accessoryViewModel = withdrawViewModelFactory.createAccessoryViewModel(for: selectedAsset,
                                                                                   totalAmount: totalAmount)
        view?.didChange(accessoryViewModel: accessoryViewModel)
    }

    private func updateAccessoryFeeViewModels() {
        guard let amount = amountInputViewModel.decimalAmount, let metadata = metadata else {
            view?.set(accessoryFees: [])
            return
        }

        let viewModels: [AccessoryFeeViewModelProtocol] = metadata.fees
            .filter({ $0.assetId != selectedAsset.identifier.identifier() })
            .compactMap { fee in
                guard
                    let asset = assets.first(where: { $0.identifier.identifier() == fee.assetId }) else {
                        return nil
                }

                let balance = balances?.first { $0.identifier == fee.assetId }
                let feeAmount = try? calculateFee(for: feeCalculationFactory,
                                                  sourceAsset: selectedAsset,
                                                  fee: fee,
                                                  amount: amount)

                return withdrawViewModelFactory.createAccessoryFeeViewModel(for: selectedAsset,
                                                                            feeAsset: asset,
                                                                            balanceData: balance,
                                                                            feeAmount: feeAmount)
        }

        view?.set(accessoryFees: viewModels)
    }

    private func updateSelectedAssetViewModel() {
        assetSelectionViewModel.isSelecting = false

        assetSelectionViewModel.assetId = selectedAsset.identifier

        let balanceData = balances?.first { $0.identifier == selectedAsset.identifier.identifier() }
        let title = withdrawViewModelFactory.createAssetTitle(for: selectedAsset, balance: balanceData)

        assetSelectionViewModel.title = title

        assetSelectionViewModel.symbol = selectedAsset.symbol
    }

    private func handleBalanceResponse(with optionalBalances: [BalanceData]?) {
        if let balances = optionalBalances {
            self.balances = balances
        }

        guard let balances = self.balances else {
            return
        }

        guard
            let assetId = assetSelectionViewModel.assetId,
            let asset = assets.first(where: { $0.identifier.identifier() == assetId.identifier() }),
            let balanceData = balances.first(where: { $0.identifier == assetId.identifier()}) else {

                if confirmationState != nil {
                   confirmationState = nil

                    let message = "Sorry, we couldn't find asset information you want to send. Please, try again later."
                    view?.showError(message: message)
                }

                return
        }

        assetSelectionViewModel.title = withdrawViewModelFactory.createAssetTitle(for: asset, balance: balanceData)

        if let currentState = confirmationState {
            confirmationState = currentState.union(.requestedAmount)
            completeConfirmation()
        }
    }

    private func handleBalanceResponse(with error: Error) {
        if confirmationState != nil {
            confirmationState = nil

            view?.didStopLoading()

            let message = "Sorry, balance checking request failed. Please, try again later."
            view?.showError(message: message)
        }
    }

    private func setupBalanceDataProvider() {
        let changesBlock = { [weak self] (changes: [DataProviderChange<[BalanceData]>]) -> Void in
            if let change = changes.first {
                switch change {
                case .insert(let items), .update(let items):
                    self?.handleBalanceResponse(with: items)
                default:
                    break
                }
            } else {
                self?.handleBalanceResponse(with: nil)
            }
        }

        let failBlock: (Error) -> Void = { [weak self] (error: Error) in
            self?.handleBalanceResponse(with: error)
        }

        let options = DataProviderObserverOptions(alwaysNotifyOnRefresh: true)
        balanceDataProvider.addObserver(self,
                                        deliverOn: .main,
                                        executing: changesBlock,
                                        failing: failBlock,
                                        options: options)
    }

    private func handleWithdraw(metadata: WithdrawMetaData?) {
        if metadata != nil {
            self.metadata = metadata
        }

        updateAmountViewModels()

        if let currentState = confirmationState {
            confirmationState = currentState.union(.requestedFee)
            completeConfirmation()
        }
    }

    private func handleWithdrawMetadata(error: Error) {
        if confirmationState != nil {
            view?.didStopLoading()

            confirmationState = nil
        }

        let message = "Sorry, we couldn't contact withdraw provider. Please, try again later."
        view?.showError(message: message)
    }

    private func updateMetadataProvider(for asset: WalletAsset) throws {
        let metaDataProvider = try dataProviderFactory.createWithdrawMetadataProvider(for: asset.identifier,
                                                                                      option: selectedOption.identifier)
        self.metaDataProvider = metaDataProvider

        setupMetadata(provider: metaDataProvider)
    }

    private func setupMetadata(provider: SingleValueProvider<WithdrawMetaData>) {
        let changesBlock = { [weak self] (changes: [DataProviderChange<WithdrawMetaData>]) -> Void in
            if let change = changes.first {
                switch change {
                case .insert(let item), .update(let item):
                    self?.handleWithdraw(metadata: item)
                default:
                    break
                }
            } else {
                self?.handleWithdraw(metadata: nil)
            }
        }

        let failBlock: (Error) -> Void = { [weak self] (error: Error) in
            self?.handleWithdrawMetadata(error: error)
        }

        let options = DataProviderObserverOptions(alwaysNotifyOnRefresh: true)
        provider.addObserver(self,
                             deliverOn: .main,
                             executing: changesBlock,
                             failing: failBlock,
                             options: options)
    }

    private func prepareWithdrawInfo(for decimalAmount: Decimal, metadata: WithdrawMetaData) throws -> WithdrawInfo {
        let amount = try IRAmountFactory.amount(from: (decimalAmount as NSNumber).stringValue)

        let fees: [FeeInfo] = try metadata.fees.compactMap { fee in
            let decimalFeeAmount = try calculateFee(for: feeCalculationFactory,
                                                    sourceAsset: selectedAsset,
                                                    fee: fee,
                                                    amount: decimalAmount)

            guard decimalFeeAmount > 0 else {
                return nil
            }

            let irFeeAmount = try IRAmountFactory.amount(from: (decimalFeeAmount as NSNumber).stringValue)
            let irAssetId = try IRAssetIdFactory.asset(withIdentifier: fee.assetId)

            var irAccountId: IRAccountId?

            if let accountId = fee.accountId {
                irAccountId = try IRAccountIdFactory.account(withIdentifier: accountId)
            }

            return FeeInfo(assetId: irAssetId, amount: irFeeAmount, accountId: irAccountId)
        }

        let providerAccountId = try IRAccountIdFactory.account(withIdentifier: metadata.providerAccountId)

        let info = WithdrawInfo(destinationAccountId: providerAccountId,
                                assetId: selectedAsset.identifier,
                                amount: amount,
                                details: descriptionInputViewModel.text,
                                fees: fees)

        return info
    }

    private func completeConfirmation() {
        guard confirmationState == .completed else {
            return
        }

        confirmationState = nil

        view?.didStopLoading()

        guard let amount = amountInputViewModel.decimalAmount else {
            logger?.error("Amount is missing to complete withdraw")
            return
        }

        guard let metadata = metadata else {
            logger?.error("Metadata is missing to complete withdraw")
            return
        }

        guard let balances = balances else {
            logger?.error("Balances are missing to complete withdraw")
            return
        }

        do {
            try checkAmountConstraints(for: feeCalculationFactory,
                                       sourceAsset: selectedAsset,
                                       balances: balances,
                                       fees: metadata.fees,
                                       amount: amount)

            let withdrawInfo = try prepareWithdrawInfo(for: amount, metadata: metadata)

            coordinator.confirm(with: withdrawInfo, asset: selectedAsset, option: selectedOption)
        } catch AmountCheckError.unsufficientFunds(let assetId) {
            let message: String

            if let asset = assets.first(where: { $0.identifier.identifier() == assetId }) {
                message = "Sorry, you don't have enough \(asset.symbol) asset to withdraw specified amount."
            } else {
                message = "Sorry, you don't have enough funds to withdraw specified amount."
            }

            view?.showError(message: message)
        } catch {
            logger?.error("Did recieve unexpected error \(error) while preparing withdrawal")
        }
    }
}

extension WithdrawAmountPresenter: WithdrawAmountPresenterProtocol {
    func setup() {
        amountInputViewModel.observable.add(observer: self)

        view?.set(title: withdrawViewModelFactory.createWithdrawTitle())
        view?.set(assetViewModel: assetSelectionViewModel)
        view?.set(amountViewModel: amountInputViewModel)
        view?.set(feeViewModel: feeViewModel)
        view?.set(descriptionViewModel: descriptionInputViewModel)

        let accessoryViewModel = withdrawViewModelFactory.createAccessoryViewModel(for: selectedAsset, totalAmount: nil)
        view?.didChange(accessoryViewModel: accessoryViewModel)

        setupBalanceDataProvider()
        setupMetadata(provider: metaDataProvider)
    }

    func confirm() {
        guard confirmationState == nil else {
            return
        }

        view?.didStartLoading()

        confirmationState = .waiting

        balanceDataProvider.refresh()
        metaDataProvider.refresh()
    }

    func presentAssetSelection() {
        var initialIndex = 0

        if let assetId = assetSelectionViewModel.assetId {
            initialIndex = assets.firstIndex(where: { $0.identifier.identifier() == assetId.identifier() }) ?? 0
        }

        let titles: [String] = assets.map { (asset) in
            let balanceData = balances?.first { $0.identifier == asset.identifier.identifier() }
            return withdrawViewModelFactory.createAssetTitle(for: asset, balance: balanceData)
        }

        coordinator.presentPicker(for: titles, initialIndex: initialIndex, delegate: self)

        assetSelectionViewModel.isSelecting = true
    }
}

extension WithdrawAmountPresenter: ModalPickerViewDelegate {
    func modalPickerViewDidCancel(_ view: ModalPickerView) {
        assetSelectionViewModel.isSelecting = false
    }

    func modalPickerView(_ view: ModalPickerView, didSelectRowAt index: Int, in context: AnyObject?) {
        do {
            let newAsset = assets[index]

            if newAsset.identifier.identifier() != selectedAsset.identifier.identifier() {
                self.metadata = nil

                try updateMetadataProvider(for: newAsset)

                self.selectedAsset = newAsset

                updateSelectedAssetViewModel()
                updateAmountViewModels()
                updateAccessoryFeeViewModels()
            }
        } catch {
            logger?.error("Unexpected error when new asset selected \(error)")
        }
    }
}

extension WithdrawAmountPresenter: AmountInputViewModelObserver {
    func amountInputDidChange() {
        updateAmountViewModels()
        updateAccessoryFeeViewModels()
    }
}
