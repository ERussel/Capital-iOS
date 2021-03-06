/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation
@testable import CommonWallet
import RobinHood

struct MockNetworkResolver: WalletNetworkResolverProtocol {
    func urlTemplate(for type: WalletRequestType) -> String {
        switch type {
        case .balance:
            return Constants.balanceUrlTemplate
        case .contacts:
            return Constants.contactsUrlTemplate
        case .history:
            return Constants.historyUrlTemplate
        case .search:
            return Constants.searchUrlTemplate
        case .transfer:
            return Constants.transferUrlTemplate
        case .transferMetadata:
            return Constants.transferMetadataUrlTemplate
        case .withdraw:
            return Constants.withdrawUrlTemplate
        case .withdrawalMetadata:
            return Constants.withdrawalMetadataUrlTemplate
        }
    }

    func adapter(for type: WalletRequestType) -> NetworkRequestModifierProtocol? {
        nil
    }

    func errorFactory(for type: WalletRequestType) -> WalletNetworkErrorFactoryProtocol? {
        nil
    }
}
