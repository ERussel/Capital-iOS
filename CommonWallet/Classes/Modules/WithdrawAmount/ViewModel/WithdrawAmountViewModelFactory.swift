/**
 * Copyright Soramitsu Co., Ltd. All Rights Reserved.
 * SPDX-License-Identifier: GPL-3.0
 */

import Foundation

protocol WithdrawAmountViewModelFactoryProtocol {
    func createWithdrawTitle() -> String
    func createFeeTitle(for sourceAsset: WalletAsset, feeAsset: WalletAsset, amount: Decimal?) -> String
    func createAssetTitle(for asset: WalletAsset, balance: BalanceData?) -> String

    func createAssetSelectionViewModel(for asset: WalletAsset, balance: BalanceData?) -> AssetSelectionViewModel
    func createAmountViewModel() -> AmountInputViewModel
    func createDescriptionViewModel() throws -> DescriptionInputViewModel
    func createMainFeeViewModel(for asset: WalletAsset, amount: Decimal?) -> FeeViewModel
    func createAccessoryFeeViewModel(for sourceAsset: WalletAsset,
                                     feeAsset: WalletAsset,
                                     balanceData: BalanceData?,
                                     feeAmount: Decimal?) -> AccessoryFeeViewModelProtocol
    func createAccessoryViewModel(for asset: WalletAsset?, totalAmount: Decimal?) -> AccessoryViewModel
}

enum WithdrawAmountViewModelFactoryError: Error {
    case missingValidator
}

final class WithdrawAmountViewModelFactory {
    let option: WalletWithdrawOption
    let amountFormatter: NumberFormatter
    let amountLimit: Decimal
    let descriptionValidatorFactory: WalletInputValidatorFactoryProtocol
    let feeInfoFactory: FeeInfoFactoryProtocol
    let assetSelectionFactory: AssetSelectionFactoryProtocol

    init(amountFormatter: NumberFormatter,
         option: WalletWithdrawOption,
         amountLimit: Decimal,
         descriptionValidatorFactory: WalletInputValidatorFactoryProtocol,
         feeInfoFactory: FeeInfoFactoryProtocol,
         assetSelectionFactory: AssetSelectionFactoryProtocol) {
        self.amountFormatter = amountFormatter
        self.option = option
        self.amountLimit = amountLimit
        self.descriptionValidatorFactory = descriptionValidatorFactory
        self.feeInfoFactory = feeInfoFactory
        self.assetSelectionFactory = assetSelectionFactory
    }
}

extension WithdrawAmountViewModelFactory: WithdrawAmountViewModelFactoryProtocol {
    func createWithdrawTitle() -> String {
        return option.shortTitle
    }

    func createAssetTitle(for asset: WalletAsset, balance: BalanceData?) -> String {
        return assetSelectionFactory.createTitle(for: asset, balanceData: balance)
    }

    func createAssetSelectionViewModel(for asset: WalletAsset, balance: BalanceData?) -> AssetSelectionViewModel {
        let title = createAssetTitle(for: asset, balance: balance)
        return AssetSelectionViewModel(assetId: asset.identifier, title: title, symbol: asset.symbol)
    }

    func createFeeTitle(for sourceAsset: WalletAsset, feeAsset: WalletAsset, amount: Decimal?) -> String {
        let title = feeInfoFactory.createWithdrawAmountTitle(for: sourceAsset,
                                                             feeAsset: feeAsset,
                                                             option: option) ?? "Transaction fee"

        guard let amount = amount, let amountString = amountFormatter.string(from: amount as NSNumber) else {
            return title
        }

        return title + " \(feeAsset.symbol)\(amountString)"
    }

    func createAmountViewModel() -> AmountInputViewModel {
        return AmountInputViewModel(amount: nil, limit: amountLimit)
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
        guard let validator = descriptionValidatorFactory
            .createWithdrawDescriptionValidator(optionId: option.identifier) else {
            throw WithdrawAmountViewModelFactoryError.missingValidator
        }

        return DescriptionInputViewModel(title: option.details,
                                         validator: validator)
    }

    func createAccessoryViewModel(for asset: WalletAsset?, totalAmount: Decimal?) -> AccessoryViewModel {
        let accessoryViewModel = AccessoryViewModel(title: "", action: "Next")

        guard let amount = totalAmount, let asset = asset else {
            return accessoryViewModel
        }

        guard let amountString = amountFormatter.string(from: amount as NSNumber) else {
            return accessoryViewModel
        }

        accessoryViewModel.title = "Total amount \(asset.symbol)\(amountString)"
        accessoryViewModel.numberOfLines = 2

        return accessoryViewModel
    }
}
