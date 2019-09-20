/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation

public struct WithdrawMetaData: Codable, Equatable {
    public var providerAccountId: String
    public var fees: [FeeData]

    public init(providerAccountId: String, fees: [FeeData]) {
        self.providerAccountId = providerAccountId
        self.fees = fees
    }
}
