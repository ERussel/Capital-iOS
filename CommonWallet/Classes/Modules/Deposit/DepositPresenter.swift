/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation
import RobinHood

final class DepositPresenter {
    weak var view: DepositViewProtocol?
    var coordinator: DepositCoordinatorProtocol

    let qrService: WalletQRServiceProtocol
    let account: WalletAccountSettingsProtocol
    let depositViewModelFactory: DepositViewModelFactoryProtocol
    let assetSelectionFactory: AssetSelectionFactoryProtocol
    let assetSelectionViewModel: AssetSelectionViewModel
    private(set) var selectedAsset: WalletAsset

    private var preferredQRSize: CGSize?
    private var currentImage: UIImage?
    private var qrOperation: Operation?

    init(view: DepositViewProtocol,
         coordinator: DepositCoordinatorProtocol,
         account: WalletAccountSettingsProtocol,
         depositViewModelFactory: DepositViewModelFactoryProtocol,
         assetSelectionFactory: AssetSelectionFactoryProtocol,
         qrService: WalletQRServiceProtocol,
         selectedAsset: WalletAsset) {

        self.view = view
        self.coordinator = coordinator
        self.account = account
        self.depositViewModelFactory = depositViewModelFactory
        self.assetSelectionFactory = assetSelectionFactory
        self.qrService = qrService
        self.selectedAsset = selectedAsset

        let title = assetSelectionFactory.createTitle(for: selectedAsset, balanceData: nil)
        assetSelectionViewModel = AssetSelectionViewModel(assetId: selectedAsset.identifier,
                                                          title: title,
                                                          symbol: selectedAsset.symbol)
    }

    private func updateSteps() {
        let steps = depositViewModelFactory.createSteps(for: selectedAsset)
        view?.set(steps: steps)
    }

    // MARK: QR generation

    private func updateQrCode() {
        if let qrSize = preferredQRSize {
            generateQR(with: qrSize)
        }
    }

    private func generateQR(with size: CGSize) {
        cancelQRGeneration()

        currentImage = nil

        let data = depositViewModelFactory.createQrData(for: selectedAsset)

        qrOperation = qrService.generate(using: data,
                                         qrSize: size,
                                         runIn: .main) { [weak self] (operationResult) in
                                            if let result = operationResult {
                                                self?.qrOperation = nil
                                                self?.processOperation(result: result)
                                            }
        }
    }

    private func cancelQRGeneration() {
        qrOperation?.cancel()
        qrOperation = nil
    }

    private func processOperation(result: Result<UIImage, Error>) {
        switch result {
        case .success(let image):
            currentImage = image
            view?.set(qrImage: image)
        case .failure:
            view?.showError(message: "Can't generate QR code")
        }
    }


}

extension DepositPresenter: DepositPresenterProtocol {
    func setup(qrSize: CGSize) {
        view?.set(assetSelectionViewModel: assetSelectionViewModel)

        preferredQRSize = qrSize

        updateSteps()
        updateQrCode()
    }

    func presentOptionsSelection() {
        let initialIndex = account.assets
            .firstIndex(where: {$0.identifier.identifier() == selectedAsset.identifier.identifier()})
            ?? 0

        let titles: [String] = account.assets.map { (asset) in
            return assetSelectionFactory.createTitle(for: asset, balanceData: nil)
        }

        coordinator.presentPicker(for: titles, initialIndex: initialIndex, delegate: self)

        assetSelectionViewModel.isSelecting = true
    }

    func share() {
        if let qrImage = currentImage {
            let sources = depositViewModelFactory.createShareSources(for: selectedAsset,
                                                                     qrImage: qrImage)
            coordinator.share(sources: sources, from: view, with: nil)
        }
    }

    func close() {
        coordinator.close()
    }
}

extension DepositPresenter: ModalPickerViewDelegate {
    func modalPickerViewDidCancel(_ view: ModalPickerView) {
        assetSelectionViewModel.isSelecting = false
    }

    func modalPickerView(_ view: ModalPickerView, didSelectRowAt index: Int, in context: AnyObject?) {
        assetSelectionViewModel.isSelecting = false

        selectedAsset = account.assets[index]

        assetSelectionViewModel.assetId = selectedAsset.identifier

        let title = assetSelectionFactory.createTitle(for: selectedAsset, balanceData: nil)

        assetSelectionViewModel.title = title

        assetSelectionViewModel.symbol = selectedAsset.symbol

        updateQrCode()
        updateSteps()
    }
}
