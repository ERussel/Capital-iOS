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
    if let feeData = fees.first(where: { $0.assetId == sourceAsset.identifier.identifier() }) {
        let feeAmount = try calculateFee(for: factory, sourceAsset: sourceAsset, fee: feeData, amount: amount)

        let totalAmount = amount + feeAmount

        try checkAmountConstraints(for: totalAmount, assetId: feeData.assetId, balances: balances)
    }

    for feeData in fees.filter({ $0.assetId != sourceAsset.identifier.identifier() }) {
        let feeAmount = try calculateFee(for: factory, sourceAsset: sourceAsset, fee: feeData, amount: amount)
        try checkAmountConstraints(for: feeAmount, assetId: feeData.assetId, balances: balances)
    }
}
