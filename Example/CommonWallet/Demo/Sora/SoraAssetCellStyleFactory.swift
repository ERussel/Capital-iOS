import Foundation
import CommonWallet

struct SoraAssetCellStyleFactory: AssetCellStyleFactoryProtocol {
    func createCellStyle(for asset: WalletAsset) -> AssetCellStyle {
        let shadow = WalletShadowStyle(offset: CGSize(width: 0.0, height: 5.0),
                                       color: .black,
                                       opacity: 0.04,
                                       blurRadius: 4.0)

        let leftFillColor: UIColor

        if asset.identifier.identifier() == String.xorAssetId {
            leftFillColor = UIColor(red: 208.0 / 255.0, green: 2.0 / 255.0, blue: 27.0 / 255.0, alpha: 1.0)
        } else {
            leftFillColor = UIColor(red: 2.0 / 255.0, green: 122.0 / 255.0, blue: 208.0 / 255.0, alpha: 1.0)
        }

        let grey = UIColor(white: 97.0 / 255.0, alpha: 1.0)

        let card = CardAssetStyle(backgroundColor: .white,
                                  leftFillColor: leftFillColor,
                                  symbol: WalletTextStyle(font: .demoHeader2, color: .white),
                                  title: WalletTextStyle(font: .demoHeader2, color: .black),
                                  subtitle: WalletTextStyle(font: .demoBodyRegular, color: grey),
                                  accessory: WalletTextStyle(font: .demoBodyRegular, color: grey),
                                  shadow: shadow,
                                  cornerRadius: 10.0)

        return .card(card)
    }
}
