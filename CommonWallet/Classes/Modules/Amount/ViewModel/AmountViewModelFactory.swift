/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation

protocol AmountViewModelFactoryProtocol {
    func createFeeTitle(for sourceAsset: WalletAsset, feeAsset: WalletAsset, amount: Decimal?) -> String
    func createAssetTitle(for asset: WalletAsset, balance: BalanceData?) -> String

    func createAssetSelectionViewModel(for asset: WalletAsset, balance: BalanceData?) -> AssetSelectionViewModel
    func createAmountViewModel(with optionalAmount: Decimal?) -> AmountInputViewModel

    func createDescriptionViewModel() throws -> DescriptionInputViewModel
    func createMainFeeViewModel(for asset: WalletAsset, amount: Decimal?) -> FeeViewModel
    func createAccessoryFeeViewModel(for sourceAsset: WalletAsset,
                                     feeAsset: WalletAsset,
                                     balanceData: BalanceData?,
                                     feeAmount: Decimal?) -> AccessoryFeeViewModelProtocol
    func createAccessoryViewModel(for peerName: String) -> AccessoryViewModelProtocol
}

enum AmountViewModelFactoryError: Error {
    case missingValidator
}

final class AmountViewModelFactory {
    let amountFormatter: NumberFormatter
    let amountLimit: Decimal
    let descriptionValidatorFactory: WalletInputValidatorFactoryProtocol
    let feeInfoFactory: FeeInfoFactoryProtocol
    let assetSelectionFactory: AssetSelectionFactoryProtocol
    let accessoryFactory: ContactAccessoryViewModelFactoryProtocol

    init(amountFormatter: NumberFormatter,
         amountLimit: Decimal,
         descriptionValidatorFactory: WalletInputValidatorFactoryProtocol,
         feeInfoFactory: FeeInfoFactoryProtocol,
         assetSelectionFactory: AssetSelectionFactoryProtocol,
         accessoryFactory: ContactAccessoryViewModelFactoryProtocol) {
        self.amountFormatter = amountFormatter
        self.amountLimit = amountLimit
        self.descriptionValidatorFactory = descriptionValidatorFactory
        self.feeInfoFactory = feeInfoFactory
        self.assetSelectionFactory = assetSelectionFactory
        self.accessoryFactory = accessoryFactory
    }
}

extension AmountViewModelFactory: AmountViewModelFactoryProtocol {
    func createAssetTitle(for asset: WalletAsset, balance: BalanceData?) -> String {
        return assetSelectionFactory.createTitle(for: asset, balanceData: balance)
    }

    func createAssetSelectionViewModel(for asset: WalletAsset, balance: BalanceData?) -> AssetSelectionViewModel {
        let title = createAssetTitle(for: asset, balance: balance)
        return AssetSelectionViewModel(assetId: asset.identifier, title: title, symbol: asset.symbol)
    }

    func createFeeTitle(for sourceAsset: WalletAsset, feeAsset: WalletAsset, amount: Decimal?) -> String {
        let title = feeInfoFactory.createTransferAmountTitle(for: sourceAsset, feeAsset: feeAsset)
            ?? "Transaction fee"

        guard let amount = amount, let amountString = amountFormatter.string(from: amount as NSNumber) else {
            return title
        }

        return title + " \(feeAsset.symbol)\(amountString)"
    }

    func createAmountViewModel(with optionalAmount: Decimal?) -> AmountInputViewModel {
        return AmountInputViewModel(amount: optionalAmount, limit: amountLimit)
    }

    func createMainFeeViewModel(for asset: WalletAsset, amount: Decimal?) -> FeeViewModel {
        let title = createFeeTitle(for: asset, feeAsset: asset, amount: amount)
        return FeeViewModel(title: title)
    }

    func createAccessoryFeeViewModel(for sourceAsset: WalletAsset,
                                     feeAsset: WalletAsset,
                                     balanceData: BalanceData?,
                                     feeAmount: Decimal?) -> AccessoryFeeViewModelProtocol {
        let title = createAssetTitle(for: feeAsset, balance: balanceData)
        let details = createFeeTitle(for: sourceAsset, feeAsset: feeAsset, amount: feeAmount)

        return AccessoryFeeViewModel(title: title, details: details)
    }

    func createDescriptionViewModel() throws -> DescriptionInputViewModel {
        guard let validator = descriptionValidatorFactory.createTransferDescriptionValidator() else {
                throw AmountViewModelFactoryError.missingValidator
        }

        return DescriptionInputViewModel(title: "Description",
                                         validator: validator)
    }

    func createAccessoryViewModel(for peerName: String) -> AccessoryViewModelProtocol {
        return accessoryFactory.createViewModel(from: peerName, fullName: peerName, action: "Next")
    }
}
