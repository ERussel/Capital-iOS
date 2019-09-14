/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation
import IrohaCommunication

typealias AccountModuleViewModel = (models: [WalletViewModelProtocol], collapsingRange: Range<Int>)

protocol AccountModuleViewModelFactoryProtocol: class {
    var assets: [WalletAsset] { get }

    func createViewModel(from balances: [BalanceData],
                         delegate: ShowMoreViewModelDelegate?) throws -> AccountModuleViewModel
}

enum AccountModuleViewModelFactoryError: Error {
    case assetsRangeMatching
    case unexpectedAsset
}

final class AccountModuleViewModelFactory {
    let context: AccountListViewModelContextProtocol
    let assets: [WalletAsset]
    let commandFactory: WalletCommandFactoryProtocol
    let commandDecoratorFactory: WalletCommandDecoratorFactoryProtocol?
    let amountFormatter: NumberFormatter

    init(context: AccountListViewModelContextProtocol,
         assets: [WalletAsset],
         commandFactory: WalletCommandFactoryProtocol,
         commandDecoratorFactory: WalletCommandDecoratorFactoryProtocol?,
         amountFormatter: NumberFormatter) {
        self.context = context
        self.assets = assets
        self.commandFactory = commandFactory
        self.commandDecoratorFactory = commandDecoratorFactory
        self.amountFormatter = amountFormatter
    }

    private func createDefaultAssetViewModel(for asset: WalletAsset, balance: BalanceData) -> AssetViewModelProtocol {
        let assetDetailsCommand = commandFactory.prepareAssetDetailsCommand(for: asset.identifier)

        let viewModel = AssetViewModel(cellReuseIdentifier: AccountModuleConstants.assetCellIdentifier,
                                       itemHeight: AccountModuleConstants.assetCellHeight,
                                       style: context.assetCellStyle,
                                       command: assetDetailsCommand)

        viewModel.assetId = asset.identifier.identifier()

        if let decimal = Decimal(string: balance.balance),
            let balanceString = amountFormatter.string(from: decimal as NSNumber) {
            viewModel.amount = balanceString
        } else {
            viewModel.amount = balance.balance
        }

        viewModel.details = asset.details
        viewModel.symbol = asset.symbol

        return viewModel
    }

    private func createDefaultActionsViewModel() -> ActionsViewModelProtocol {
        let assetId = assets.count == 1 ? assets.first?.identifier : nil

        var sendCommand: WalletCommandProtocol = commandFactory.prepareSendCommand(for: assetId)

        if let sendDecorator = commandDecoratorFactory?.createSendCommandDecorator(with: commandFactory) {
            sendDecorator.undelyingCommand = sendCommand
            sendCommand = sendDecorator
        }

        let sendViewModel = ActionViewModel(title: "Send",
                                            style: context.actionsStyle.sendText,
                                            command: sendCommand)

        var receiveCommand: WalletCommandProtocol = commandFactory.prepareReceiveCommand(for: assetId)

        if let receiveDecorator = commandDecoratorFactory?.createReceiveCommandDecorator(with: commandFactory) {
            receiveDecorator.undelyingCommand = receiveCommand
            receiveCommand = receiveDecorator
        }

        let receiveViewModel = ActionViewModel(title: "Receive",
                                               style: context.actionsStyle.receiveText,
                                               command: receiveCommand)

        return ActionsViewModel(cellReuseIdentifier: AccountModuleConstants.actionsCellIdentifier,
                                itemHeight: AccountModuleConstants.actionsCellHeight,
                                sendViewModel: sendViewModel,
                                receiveViewModel: receiveViewModel)
    }

    private func createDefaultShowMoreViewModel(with delegate: ShowMoreViewModelDelegate?)
        -> ShowMoreViewModelProtocol {
        let viewModel = ShowMoreViewModel(cellReuseIdentifier: AccountModuleConstants.showMoreCellIdentifier,
                                          itemHeight: AccountModuleConstants.showMoreCellHeight,
                                          style: context.showMoreCellStyle)
        viewModel.delegate = delegate
        return viewModel
    }
}

extension AccountModuleViewModelFactory: AccountModuleViewModelFactoryProtocol {
    func createViewModel(from balances: [BalanceData],
                         delegate: ShowMoreViewModelDelegate?) throws -> AccountModuleViewModel {

        var viewModels = try context.viewModelFactoryContainer.viewModelFactories.map { try $0() }

        var collapsingRange = viewModels.count..<viewModels.count

        if balances.count > 0 {
            let assetViewModels: [AssetViewModelProtocol] = balances.compactMap { (balance) in
                guard let asset = assets.first(where: { $0.identifier.identifier() == balance.identifier }) else {
                    return nil
                }

                if let assetViewModel = context.accountListViewModelFactory?
                    .createAssetViewModel(for: asset, balance: balance, commandFactory: commandFactory) {
                    return assetViewModel
                } else {
                    return createDefaultAssetViewModel(for: asset, balance: balance)
                }
            }

            var assetsBlockLength = assetViewModels.count

            let upper = context.viewModelFactoryContainer.assetsIndex + assetsBlockLength
            let lower = context.viewModelFactoryContainer.assetsIndex + Int(context.minimumVisibleAssets)
            collapsingRange = min(lower, upper)..<upper

            viewModels.insert(contentsOf: assetViewModels, at: context.viewModelFactoryContainer.assetsIndex)

            if !collapsingRange.isEmpty {
                if let showMoreViewModel = context.accountListViewModelFactory?.createShowMoreViewModel(for: delegate) {
                    viewModels.append(showMoreViewModel)
                } else {
                    let showMoreViewModel = createDefaultShowMoreViewModel(with: delegate)
                    viewModels.append(showMoreViewModel)
                }

                assetsBlockLength += 1
            }

            let assetId: IRAssetId?

            if assets.count == 1 {
                assetId = assets.first?.identifier
            } else {
                assetId = nil
            }

            let actionsIndex = context.viewModelFactoryContainer.actionsIndex + assetsBlockLength - 1

            if let actionsViewModel = context.accountListViewModelFactory?
                .createActionsViewModel(for: assetId, commandFactory: commandFactory) {

                viewModels.insert(actionsViewModel, at: actionsIndex)
            } else {
                let actionsViewModel = createDefaultActionsViewModel()
                viewModels.insert(actionsViewModel, at: actionsIndex)
            }
        }

        return AccountModuleViewModel(models: viewModels, collapsingRange: collapsingRange)
    }
}