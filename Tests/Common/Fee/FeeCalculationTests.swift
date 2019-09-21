/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import XCTest
@testable import CommonWallet
import IrohaCommunication

class FeeCalculationTests: XCTestCase {

    func testFixedFeeCalculationSuccess() {
        do {
            let feeFactory = FeeCalculationFactory()

            let account = try createRandomAccountSettings(for: 1)
            let asset = account.assets[0]

            let validValues: [String] = ["0", "10", "1e+6"]

            for value in validValues {
                let feeData = FeeData(assetId: asset.identifier.identifier(),
                                      type: FeeType.fixed.rawValue,
                                      parameters: [value])
                let transferCalculator = try feeFactory.createTransferFeeStrategy(for: asset, fee: feeData)

                let expectedValue = Decimal(string: value)!

                let transferFee = try transferCalculator.calculate(for: 1.2)
                XCTAssertEqual(transferFee, expectedValue)

                let option = createRandomWithdrawOption()
                let withdrawCalculator = try feeFactory.createWithdrawFeeStrategy(for: asset,
                                                                                  option: option,
                                                                                  fee: feeData)

                let withdrawFee = try withdrawCalculator.calculate(for: 1.2)
                XCTAssertEqual(withdrawFee, expectedValue)
            }

        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testFactorFeeCalculationSuccess() {
        do {
            let feeFactory = FeeCalculationFactory()

            let account = try createRandomAccountSettings(for: 1)
            let asset = account.assets[0]

            let validValues: [String] = ["0", "10", "1e+6"]
            let amount: Decimal = 1.2

            for value in validValues {
                let feeData = FeeData(assetId: asset.identifier.identifier(),
                                      type: FeeType.factor.rawValue,
                                      parameters: [value])

                let transferCalculator = try feeFactory.createTransferFeeStrategy(for: asset,
                                                                                  fee: feeData)

                let decimalValue = Decimal(string: value)!

                let transferFee = try transferCalculator.calculate(for: 1.2)
                XCTAssertEqual(transferFee, amount * decimalValue)

                let option = createRandomWithdrawOption()
                let withdrawCalculator = try feeFactory.createWithdrawFeeStrategy(for: asset,
                                                                                  option: option,
                                                                                  fee: feeData)

                let withdrawFee = try withdrawCalculator.calculate(for: 1.2)
                XCTAssertEqual(withdrawFee, amount * decimalValue)
            }

        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testTransferFeeInvalidParametersError() {
        do {
            let feeFactory = FeeCalculationFactory()

            let account = try createRandomAccountSettings(for: 1)
            let asset = account.assets[0]

            let feeData = FeeData(assetId: asset.identifier.identifier(),
                                  type: FeeType.fixed.rawValue,
                                  parameters: [])

            _ = try feeFactory.createTransferFeeStrategy(for: asset, fee: feeData)
                .calculate(for: 1.2)
        } catch FeeCalculationFactoryError.invalidParameters {
            // expect this error
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testWithdrawFeeInvalidParametersError() {
        do {
            let feeFactory = FeeCalculationFactory()

            let account = try createRandomAccountSettings(for: 1)
            let asset = account.assets[0]

            let option = createRandomWithdrawOption()

            let feeData = FeeData(assetId: asset.identifier.identifier(),
                                  type: FeeType.fixed.rawValue,
                                  parameters: [])

            _ = try feeFactory.createWithdrawFeeStrategy(for: asset,
                                                         option: option,
                                                         fee: feeData)
                .calculate(for: 1.2)
        } catch FeeCalculationFactoryError.invalidParameters {
            // expect this error
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
}
