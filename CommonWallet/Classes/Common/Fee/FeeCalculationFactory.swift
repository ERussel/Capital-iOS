/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation
import IrohaCommunication

enum FeeType: String, Codable, Equatable {
    case factor = "FACTOR"
    case fixed = "FIXED"
}

public enum FeeCalculationFactoryError: Error {
    case unknownFeeType
    case invalidParameters
}

public protocol FeeCalculationFactoryProtocol {
    func createTransferFeeStrategy(for asset: WalletAsset, fee: FeeData) throws -> FeeCalculationStrategyProtocol
    func createWithdrawFeeStrategy(for asset: WalletAsset,
                                   option: WalletWithdrawOption,
                                   fee: FeeData) throws -> FeeCalculationStrategyProtocol
}

public extension FeeCalculationFactoryProtocol {
    func createTransferFeeStrategy(for asset: WalletAsset, fee: FeeData) throws -> FeeCalculationStrategyProtocol {
        return try createFeeStrategy(for: fee.type, parameters: fee.decimalParameters ?? [])
    }

    func createWithdrawFeeStrategy(for asset: WalletAsset,
                                   option: WalletWithdrawOption,
                                   fee: FeeData) throws -> FeeCalculationStrategyProtocol {
        return try createFeeStrategy(for: fee.type, parameters: fee.decimalParameters ?? [])
    }

    private func createFeeStrategy(for feeTypeString: String,
                                   parameters: [Decimal]) throws -> FeeCalculationStrategyProtocol {
        guard let feeType = FeeType(rawValue: feeTypeString) else {
            throw FeeCalculationFactoryError.unknownFeeType
        }

        switch feeType {
        case .fixed:
            return try createFixedFeeStrategy(for: parameters)
        case .factor:
            return try createFactorFeeStrategy(for: parameters)
        }
    }

    private func createFixedFeeStrategy(for parameters: [Decimal]) throws -> FeeCalculationStrategyProtocol {
        guard let value = parameters.first else {
            throw FeeCalculationFactoryError.invalidParameters
        }

        return FixedFeeStrategy(value: value)
    }

    private func createFactorFeeStrategy(for parameters: [Decimal]) throws -> FeeCalculationStrategyProtocol {
        guard let rate = parameters.first else {
            throw FeeCalculationFactoryError.invalidParameters
        }

        return FactorFeeStrategy(rate: rate)
    }
}

struct FeeCalculationFactory: FeeCalculationFactoryProtocol {}
