/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation

final class ReceiveAssetSelectionTitleFactory: AssetSelectionFactoryProtocol {
    
    func createTitle(for asset: WalletAsset?, balanceData: BalanceData?, locale: Locale) -> String {
        guard let asset = asset else {
            return L10n.AssetSelection.noAsset
        }

        return "\(asset.details), \(asset.symbol)"
    }
    
}
