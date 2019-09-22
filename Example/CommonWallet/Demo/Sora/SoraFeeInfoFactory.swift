import Foundation
import CommonWallet

struct SoraFeeInfoFactory: FeeInfoFactoryProtocol {
    func createTransactionDetailsTitle(for transactionType: WalletTransactionType,
                                       sourceAsset: WalletAsset,
                                       feeAsset: WalletAsset) -> String? {
        switch feeAsset.identifier.identifier() {
        case String.xorAssetId:
            return "Fee"
        case String.ethAssetId:
            return "Payment for Ethereum gas"
        default:
            return nil
        }
    }

    func createTransferAmountTitle(for sourceAsset: WalletAsset, feeAsset: WalletAsset) -> String? {
        return "Transaction fee"
    }

    func createWithdrawAmountTitle(for sourceAsset: WalletAsset,
                                   feeAsset: WalletAsset,
                                   option: WalletWithdrawOption) -> String? {
        switch feeAsset.identifier.identifier() {
        case String.xorAssetId:
            return "Transaction fee"
        case String.ethAssetId:
            return "Payment for Ethereum gas"
        default:
            return nil
        }
    }
}
