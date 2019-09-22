import Foundation
import CommonWallet

struct SoraAccountShareFactory: AccountShareFactoryProtocol {
    let assets: [WalletAsset]
    let amountFormatter: NumberFormatter

    func createSources(for receiveInfo: ReceiveInfo, qrImage: UIImage) -> [Any] {
        var title: String = "My Sora Network address"

        if receiveInfo.assetId != nil || receiveInfo.amount != nil {
            title += " to Receive"
        }

        if let amount = receiveInfo.amount?.value,
            let amountDecimal = Decimal(string: amount),
            let formattedAmount = amountFormatter.string(from: amountDecimal as NSNumber) {
            title += " \(formattedAmount)"
        }

        if let assetId = receiveInfo.assetId,
            let asset = assets.first(where: { $0.identifier.identifier() == assetId.identifier() }) {
            title += " \(asset.details)"
        }

        title += ":"

        return [qrImage, title, receiveInfo.accountId.identifier()]
    }
}
