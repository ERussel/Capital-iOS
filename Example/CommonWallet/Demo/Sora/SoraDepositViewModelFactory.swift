/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation
import CommonWallet

struct SoraDepositViewModelFactory: DepositViewModelFactoryProtocol {
    let ethereumAddress: String

    func createSteps(for asset: WalletAsset) -> [StepViewModel] {
        var steps: [StepViewModel] = []
        steps.append(StepViewModel(index: 1, title: "Scan or export your deposit Ethereum address"))

        switch asset.identifier.identifier() {
        case String.xorAssetId:
            steps.append(StepViewModel(index: 2, title: "Send XOR token to the Ethereum address"))

            let title3 = "Return to the Sora app and wait until your XOR balance updates"
            steps.append(StepViewModel(index: 3, title: title3))
        case String.ethAssetId:
            steps.append(StepViewModel(index: 2, title: "Send Ether to the Ethereum address"))

            let title3 = "Return to the Sora app and wait until your Ether balance updates"
            steps.append(StepViewModel(index: 3, title: title3))
        default:
            break
        }

        return steps
    }

    func createQrData(for asset: WalletAsset) -> Data {
        return ethereumAddress.data(using: .utf8)!
    }

    func createShareSources(for asset: WalletAsset, qrImage: UIImage) -> [Any] {
        let title: String

        if asset.identifier.identifier() == String.xorAssetId {
            title = "To receive XOR asset send XOR token to the Ethereum address:"
        } else {
            title = "To receive Ether asset send Ether to the Ethereum address:"
        }

        return [qrImage, title, ethereumAddress]
    }
}
