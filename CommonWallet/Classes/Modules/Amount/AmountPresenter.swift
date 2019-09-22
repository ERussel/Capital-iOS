/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation
import RobinHood
import IrohaCommunication

enum AmountPresenterError: Error {
    case missingSelectedAsset
}

struct TransferCheckingState: OptionSet {
    typealias RawValue = UInt8

    static let waiting = TransferCheckingState(rawValue: 0)
    static let requestedAmount = TransferCheckingState(rawValue: 1)
    static let requestedFee = TransferCheckingState(rawValue: 2)
    static let completed = TransferCheckingState.requestedAmount.union(.requestedFee)

    var rawValue: TransferCheckingState.RawValue

    init(rawValue: TransferCheckingState.RawValue) {
        self.rawValue = rawValue
    }
}

final class AmountPresenter {

    weak var view: AmountViewProtocol?
    var coordinator: AmountCoordinatorProtocol
    var logger: WalletLoggerProtocol?
    
    private var assetSelectionViewModel: AssetSelectionViewModel
    private var amountInputViewModel: AmountInputViewModel
    private var descriptionInputViewModel: DescriptionInputViewModel
    private var accessoryViewModel: AccessoryViewModelProtocol
    private var feeViewModel: FeeViewModel

    private var feeCalculationFactory: FeeCalculationFactoryProtocol
    private var transferViewModelFactory: AmountViewModelFactoryProtocol

    private let dataProviderFactory: DataProviderFactoryProtocol
    private let balanceDataProvider: SingleValueProvider<[BalanceData]>
    private var metadataProvider: SingleValueProvider<TransferMetaData>

    private var balances: [BalanceData]?
    private var metadata: TransferMetaData?
    private var selectedAsset: WalletAsset
    private let account: WalletAccountSettingsProtocol
    private var payload: AmountPayload

    private(set) var confirmationState: TransferCheckingState?
    
    init(view: AmountViewProtocol,
         coordinator: AmountCoordinatorProtocol,
         payload: AmountPayload,
         dataProviderFactory: DataProviderFactoryProtocol,
         feeCalculationFactory: FeeCalculationFactoryProtocol,
         account: WalletAccountSettingsProtocol,
         transferViewModelFactory: AmountViewModelFactoryProtocol) throws {

        if let assetId = payload.receiveInfo.assetId, let asset = account.asset(for: assetId.identifier()) {
            selectedAsset = asset
        } else if let asset = account.assets.first {
            selectedAsset = asset
        } else {
            throw AmountPresenterError.missingSelectedAsset
        }

        self.view = view
        self.coordinator = coordinator
        self.account = account
        self.payload = payload

        self.dataProviderFactory = dataProviderFactory
        self.balanceDataProvider = try dataProviderFactory.createBalanceDataProvider()
        self.metadataProvider = try dataProviderFactory.createTransferMetadataProvider(for: selectedAsset.identifier)

        self.feeCalculationFactory = feeCalculationFactory
        self.transferViewModelFactory = transferViewModelFactory
        
        descriptionInputViewModel = try transferViewModelFactory.createDescriptionViewModel()

        assetSelectionViewModel = transferViewModelFactory.createAssetSelectionViewModel(for: selectedAsset,
                                                                                         balance: nil)
        assetSelectionViewModel.canSelect = account.assets.count > 1

        var decimalAmount: Decimal?

        if let amount = payload.receiveInfo.amount {
            decimalAmount = Decimal(string: amount.value)
        }

        amountInputViewModel = transferViewModelFactory.createAmountViewModel(with: decimalAmount)

        accessoryViewModel = transferViewModelFactory.createAccessoryViewModel(for: payload.receiverName)

        feeViewModel = transferViewModelFactory.createMainFeeViewModel(for: selectedAsset, amount: nil)
        feeViewModel.isLoading = true
    }

    private func updateMainFeeViewModel() {
        guard let amount = amountInputViewModel.decimalAmount, let metadata = metadata else {
                feeViewModel.title = transferViewModelFactory.createFeeTitle(for: selectedAsset,
                                                                             feeAsset: selectedAsset,
                                                                             amount: nil)
                feeViewModel.isLoading = true
                return
        }

        guard let fee = metadata.fees.first(where: { $0.assetId == selectedAsset.identifier.identifier() }) else {
            feeViewModel.title = transferViewModelFactory.createFeeTitle(for: selectedAsset,
                                                                         feeAsset: selectedAsset,
                                                                         amount: 0.0)
            feeViewModel.isLoading = false
            return
        }

        guard
            let feeAmount = try? calculateFee(for: feeCalculationFactory,
                                              sourceAsset: selectedAsset,
                                              fee: fee,
                                              amount: amount) else {
            feeViewModel.title = transferViewModelFactory.createFeeTitle(for: selectedAsset,
                                                                         feeAsset: selectedAsset,
                                                                         amount: nil)
            feeViewModel.isLoading = true
            return
        }

        feeViewModel.title = transferViewModelFactory.createFeeTitle(for: selectedAsset,
                                                                     feeAsset: selectedAsset,
                                                                     amount: feeAmount)
        feeViewModel.isLoading = false
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
                    let asset = account.asset(for: fee.assetId) else {
                    return nil
                }

                let balance = balances?.first { $0.identifier == fee.assetId }
                let feeAmount = try? calculateFee(for: feeCalculationFactory,
                                                  sourceAsset: selectedAsset,
                                                  fee: fee,
                                                  amount: amount)

                return transferViewModelFactory.createAccessoryFeeViewModel(for: selectedAsset,
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
        let title = transferViewModelFactory.createAssetTitle(for: selectedAsset, balance: balanceData)

        assetSelectionViewModel.title = title

        assetSelectionViewModel.symbol = selectedAsset.symbol
    }
    
    private func handleResponse(with optionalBalances: [BalanceData]?) {
        if let balances = optionalBalances {
            self.balances = balances
        }

        guard let balances = self.balances else {
            return
        }
        
        guard
            let assetId = assetSelectionViewModel.assetId,
            let asset = account.asset(for: assetId.identifier()),
            let balanceData = balances.first(where: { $0.identifier == assetId.identifier()}) else {

                if confirmationState != nil {
                    confirmationState = nil

                    let message = "Sorry, we couldn't find asset information you want to send. Please, try again later."
                    view?.showError(message: message)
                }

            return
        }

        assetSelectionViewModel.title = transferViewModelFactory.createAssetTitle(for: asset, balance: balanceData)

        if let currentState = confirmationState {
            confirmationState = currentState.union(.requestedAmount)
            completeConfirmation()
        }
    }

    private func handleResponse(with error: Error) {
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
                    self?.handleResponse(with: items)
                default:
                    break
                }
            } else {
                self?.handleResponse(with: nil)
            }
        }
        
        let failBlock: (Error) -> Void = { [weak self] (error: Error) in
            self?.handleResponse(with: error)
        }

        let options = DataProviderObserverOptions(alwaysNotifyOnRefresh: true)
        balanceDataProvider.addObserver(self,
                                        deliverOn: .main,
                                        executing: changesBlock,
                                        failing: failBlock,
                                        options: options)
    }

    private func handleTransfer(metadata: TransferMetaData?) {
        if metadata != nil {
            self.metadata = metadata
        }

        updateMainFeeViewModel()
        updateAccessoryFeeViewModels()

        if let currentState = confirmationState {
            confirmationState = currentState.union(.requestedFee)
            completeConfirmation()
        }
    }

    private func handleTransferMetadata(error: Error) {
        if confirmationState != nil {
            view?.didStopLoading()

            confirmationState = nil
        }

        let message = "Sorry, we coudn't contact transfer provider. Please, try again later."
        view?.showError(message: message)
    }

    private func updateMetadataProvider(for asset: WalletAsset) throws {
        let metaDataProvider = try dataProviderFactory.createTransferMetadataProvider(for: asset.identifier)
        self.metadataProvider = metaDataProvider

        setupMetadata(provider: metaDataProvider)
    }

    private func setupMetadata(provider: SingleValueProvider<TransferMetaData>) {
        let changesBlock = { [weak self] (changes: [DataProviderChange<TransferMetaData>]) -> Void in
            if let change = changes.first {
                switch change {
                case .insert(let item), .update(let item):
                    self?.handleTransfer(metadata: item)
                default:
                    break
                }
            } else {
                self?.handleTransfer(metadata: nil)
            }
        }

        let failBlock: (Error) -> Void = { [weak self] (error: Error) in
            self?.handleTransferMetadata(error: error)
        }

        let options = DataProviderObserverOptions(alwaysNotifyOnRefresh: true)
        provider.addObserver(self,
                             deliverOn: .main,
                             executing: changesBlock,
                             failing: failBlock,
                             options: options)
    }

    private func prepareTransferInfo(for decimalAmount: Decimal, metadata: TransferMetaData) throws -> TransferInfo {
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

        return TransferInfo(source: account.accountId,
                            destination: payload.receiveInfo.accountId,
                            amount: amount,
                            asset: selectedAsset.identifier,
                            details: descriptionInputViewModel.text,
                            fees: fees)
    }

    private func completeConfirmation() {
        guard confirmationState == .completed else {
            return
        }

        confirmationState = nil

        view?.didStopLoading()

        guard let amount = amountInputViewModel.decimalAmount else {
            logger?.error("Amount is missing to complete transfer")
            return
        }

        guard let metadata = metadata else {
            logger?.error("Metadata is missing to complete transfer")
            return
        }

        guard let balances = balances else {
            logger?.error("Balances are missing to complete transfer")
            return
        }

        do {
            try checkAmountConstraints(for: feeCalculationFactory,
                                       sourceAsset: selectedAsset,
                                       balances: balances,
                                       fees: metadata.fees,
                                       amount: amount)

            let transferInfo = try prepareTransferInfo(for: amount, metadata: metadata)
            let composedPayload = TransferPayload(transferInfo: transferInfo,
                                                  receiverName: payload.receiverName,
                                                  assetSymbol: selectedAsset.symbol)

            coordinator.confirm(with: composedPayload)
        } catch AmountCheckError.unsufficientFunds(let assetId) {
            let message: String

            if let asset = account.asset(for: assetId) {
                message = "Sorry, you don't have enough \(asset.details) asset to transfer specified amount."
            } else {
                message = "Sorry, you don't have enough funds to transfer specified amount."
            }

            view?.showError(message: message)
        } catch {
            logger?.error("Did recieve unexpected error \(error) while preparing transfer")
        }
    }
}


extension AmountPresenter: AmountPresenterProtocol {

    func setup() {
        amountInputViewModel.observable.add(observer: self)

        view?.set(assetViewModel: assetSelectionViewModel)
        view?.set(amountViewModel: amountInputViewModel)
        view?.set(descriptionViewModel: descriptionInputViewModel)
        view?.set(accessoryViewModel: accessoryViewModel)
        view?.set(feeViewModel: feeViewModel)

        setupBalanceDataProvider()
        setupMetadata(provider: metadataProvider)
    }
    
    func confirm() {
        guard confirmationState == nil else {
            return
        }

        view?.didStartLoading()

        confirmationState = .waiting

        balanceDataProvider.refresh()
        metadataProvider.refresh()
    }
    
    func presentAssetSelection() {
        var initialIndex = 0

        if let assetId = assetSelectionViewModel.assetId {
            initialIndex = account.assets.firstIndex(where: { $0.identifier.identifier() == assetId.identifier() }) ?? 0
        }

        let titles: [String] = account.assets.map { (asset) in
            let balanceData = balances?.first { $0.identifier == asset.identifier.identifier() }
            return transferViewModelFactory.createAssetTitle(for: asset, balance: balanceData)
        }

        coordinator.presentPicker(for: titles, initialIndex: initialIndex, delegate: self)

        assetSelectionViewModel.isSelecting = true
    }

    func close() {
        coordinator.close()
    }
}

extension AmountPresenter: ModalPickerViewDelegate {
    func modalPickerViewDidCancel(_ view: ModalPickerView) {
        assetSelectionViewModel.isSelecting = false
    }

    func modalPickerView(_ view: ModalPickerView, didSelectRowAt index: Int, in context: AnyObject?) {
        do {
            let newAsset = account.assets[index]

            if newAsset.identifier.identifier() != selectedAsset.identifier.identifier() {
                self.metadata = nil

                try updateMetadataProvider(for: newAsset)

                self.selectedAsset = newAsset

                updateSelectedAssetViewModel()
                updateMainFeeViewModel()
                updateAccessoryFeeViewModels()
            }
        } catch {
            logger?.error("Unexpected error when new asset selected \(error)")
        }
    }
}

extension AmountPresenter: AmountInputViewModelObserver {
    func amountInputDidChange() {
        updateMainFeeViewModel()
        updateAccessoryFeeViewModels()
    }
}
