/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation

func calculateFee(for factory: FeeCalculationFactoryProtocol,
                  sourceAsset: WalletAsset,
                  fee: FeeData,
                  amount: Decimal) throws -> Decimal {
    let calculator = try factory.createTransferFeeStrategy(for: sourceAsset, fee: fee)
    return try calculator.calculate(for: amount)
}

enum AmountCheckError: Error {
    case unsufficientFunds(assetId: String)
}

func checkAmountConstraints(for amount: Decimal, assetId: String, balances: [BalanceData]) throws {
    guard
        let balanceData = balances.first(where: { $0.identifier == assetId }),
        let decimalBalance = balanceData.deceimalBalance else {
           throw AmountCheckError.unsufficientFunds(assetId: assetId)
    }

    if amount > decimalBalance {
        throw AmountCheckError.unsufficientFunds(assetId: assetId)
    }
}

func checkAmountConstraints(for factory: FeeCalculationFactoryProtocol,
                            sourceAsset: WalletAsset,
                            balances: [BalanceData],
                            fees: [FeeData],
                            amount: Decimal) throws {
    var totalAmount = amount

    let mainFees = fees.filter({ $0.assetId == sourceAsset.identifier.identifier() })
    let otherFees = fees.filter({ $0.assetId != sourceAsset.identifier.identifier() })

    try mainFees.forEach { fee in
        let feeAmount = try calculateFee(for: factory, sourceAsset: sourceAsset, fee: fee, amount: amount)
        totalAmount += feeAmount
    }

    try checkAmountConstraints(for: totalAmount, assetId: sourceAsset.identifier.identifier(), balances: balances)

    for feeData in otherFees {
        let feeAmount = try calculateFee(for: factory, sourceAsset: sourceAsset, fee: feeData, amount: amount)
        try checkAmountConstraints(for: feeAmount, assetId: feeData.assetId, balances: balances)
    }
}
