/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import XCTest
@testable import CommonWallet
import IrohaCommunication

class HistoryViewModelFactoryTests: XCTestCase {
    func testFeeInclusion() {
        do {
            var assetDataWithFee = try createRandomAssetTransactionData()

            let assetId = try IRAssetIdFactory.asset(withIdentifier: assetDataWithFee.assetId)
            let asset = WalletAsset(identifier: assetId, symbol: "", details: "")

            guard let type = WalletTransactionType.required.first(where: { !$0.isIncome })?.backendName else {
                XCTFail("Unexpected type")
                return
            }

            assetDataWithFee.type = type

            for includesFee in [false, true] {
                var viewModels: [TransactionSectionViewModel] = []
                let viewModelFactory = createViewModelFactory(for: [asset], includesFee: includesFee)

                _ = try viewModelFactory.merge(newItems: [assetDataWithFee], into: &viewModels)

                guard let viewModel = viewModels.first?.items.first else {
                    XCTFail("Unexpected empty view model")
                    return
                }

                guard let amount = Decimal(string: assetDataWithFee.amount) else {
                        XCTFail("Unexpected amount")
                        return
                }

                var expectedAmount = amount

                if includesFee {
                    guard let fees = assetDataWithFee.fees else {
                        XCTFail("Unexpected missing fee")
                        return
                    }

                    expectedAmount = fees.filter({ $0.assetId == asset.identifier.identifier() })
                        .reduce(expectedAmount) { (result, fee) in
                            if let feeValue = fee.decimalAmount {
                                return result + feeValue
                            } else {
                                return result
                            }
                    }
                }

                guard let currentAmount = viewModelFactory.amountFormatter.number(from: viewModel.amount) else {
                    XCTFail("Unexpected current amount")
                    return
                }

                XCTAssertEqual(expectedAmount, currentAmount.decimalValue)
            }

        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    // MARK: Private

    private func createViewModelFactory(for assets: [WalletAsset],
                                        includesFee: Bool) -> HistoryViewModelFactory {
        let dateFormatterFactory = TransactionListSectionFormatterFactory.self
        let dateFormatterProvider = DateFormatterProvider(dateFormatterFactory: dateFormatterFactory,
                                                          dayChangeHandler: DayChangeHandler())

        let viewModelFactory = HistoryViewModelFactory(dateFormatterProvider: dateFormatterProvider,
                                                       amountFormatter: NumberFormatter(),
                                                       assets: assets,
                                                       transactionTypes: WalletTransactionType.required,
                                                       includesFeeInAmount: includesFee)

        return viewModelFactory
    }
}
