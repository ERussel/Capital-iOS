/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation
import IrohaCommunication


public struct ReceiveInfo {
    enum CodingKeys: String, CodingKey {
        case accountId
        case assetId
        case amount
        case details
    }

    public var accountId: IRAccountId
    public var assetId: IRAssetId?
    public var amount: IRAmount?
    public var details: String?
}

extension ReceiveInfo: Equatable {
    public static func == (lhs: ReceiveInfo, rhs: ReceiveInfo) -> Bool {
        return lhs.accountId.identifier() == rhs.accountId.identifier() &&
            lhs.amount?.value == rhs.amount?.value &&
            lhs.assetId?.identifier() == rhs.assetId?.identifier() &&
            lhs.details == rhs.details
    }
}

extension ReceiveInfo: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let accountString = try container.decode(String.self, forKey: .accountId)
        accountId = try IRAccountIdFactory.account(withIdentifier: accountString)

        let assetString = try container.decode(String.self, forKey: .assetId)
        assetId = try IRAssetIdFactory.asset(withIdentifier: assetString)

        if let amountString = try container.decodeIfPresent(String.self, forKey: .amount) {
            amount = try IRAmountFactory.amount(from: amountString)
        }

        details = try container.decodeIfPresent(String.self, forKey: .details)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(accountId.identifier(), forKey: .accountId)

        if let assetId = assetId {
            try container.encode(assetId.identifier(), forKey: .assetId)
        }

        if let amount = amount {
            try container.encode(amount.value, forKey: .amount)
        }

        if let details = details {
            try container.encode(details, forKey: .details)
        }
    }
}
