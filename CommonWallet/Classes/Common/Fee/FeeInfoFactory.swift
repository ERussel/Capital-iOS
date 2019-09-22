/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation

public protocol FeeInfoFactoryProtocol {
    func createTransactionDetailsTitle(for transactionType: WalletTransactionType,
                                       sourceAsset: WalletAsset,
                                       feeAsset: WalletAsset) -> String?

    func createTransferAmountTitle(for sourceAsset: WalletAsset, feeAsset: WalletAsset) -> String?
    func createWithdrawAmountTitle(for sourceAsset: WalletAsset,
                                   feeAsset: WalletAsset,
                                   option: WalletWithdrawOption) -> String?
}

public extension FeeInfoFactoryProtocol {
    func createTransactionDetailsTitle(for transactionType: WalletTransactionType,
                                       sourceAsset: WalletAsset,
                                       feeAsset: WalletAsset) -> String? {
        return "Fee"
    }

    func createTransferAmountTitle(for sourceAsset: WalletAsset, feeAsset: WalletAsset) -> String? {
        return "Transaction fee"
    }

    func createWithdrawAmountTitle(for sourceAsset: WalletAsset,
                                   feeAsset: WalletAsset,
                                   option: WalletWithdrawOption) -> String? {
        return "Transaction fee"
    }
}

struct FeeInfoFactory: FeeInfoFactoryProtocol {}
