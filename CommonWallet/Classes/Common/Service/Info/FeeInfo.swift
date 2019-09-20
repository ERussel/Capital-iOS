import Foundation
import IrohaCommunication

public struct FeeInfo {
    public let accountId: IRAccountId?
    public let assetId: IRAssetId
    public let amount: IRAmount

    public init(assetId: IRAssetId, amount: IRAmount, accountId: IRAccountId?) {
        self.assetId = assetId
        self.amount = amount
        self.accountId = accountId
    }
}
