import Foundation

public protocol DepositViewModelFactoryProtocol {
    func createSteps(for asset: WalletAsset) -> [StepViewModel]
    func createQrData(for asset: WalletAsset) -> Data
    func createShareSources(for asset: WalletAsset, qrImage: UIImage) -> [Any]
}
