/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation
import IrohaCommunication

public struct TransferMetadataInfo {
    public var assetId: IRAssetId
    public var source: IRAccountId
    public var destination: IRAccountId

    public init(assetId: IRAssetId, source: IRAccountId, destination: IRAccountId) {
        self.assetId = assetId
        self.source = source
        self.destination = destination
    }
}