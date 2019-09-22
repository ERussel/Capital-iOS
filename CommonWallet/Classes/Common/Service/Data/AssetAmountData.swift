/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation

public struct AssetAmountData: Codable, Equatable {
    public let assetId: String
    public let amount: String

    public init(assetId: String, amount: String) {
        self.assetId = assetId
        self.amount = amount
    }
}

extension AssetAmountData {
    public var decimalAmount: Decimal? {
        return Decimal(string: amount)
    }
}
