import UIKit

protocol DepositViewProtocol: ControllerBackedProtocol, AlertPresentable {
    func set(qrImage: UIImage)
    func set(assetSelectionViewModel: AssetSelectionViewModelProtocol)
    func set(steps: [StepViewModel])
}

protocol DepositPresenterProtocol: class {
    func setup(qrSize: CGSize)
    func presentOptionsSelection()
    func share()
    func close()
}

protocol DepositCoordinatorProtocol: CoordinatorProtocol, PickerPresentable, SharingPresentable {
    func close()
}

protocol DepositAssemblyProtocol: class {
    static func assembleView(resolver: ResolverProtocol) -> DepositViewProtocol?
}
