/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/


import Foundation

public protocol WalletErrorContentProtocol {
    var title: String { get }
    var message: String { get }
}

public protocol WalletErrorContentConvertible {
    func toErrorContent(for locale: Locale?) -> WalletErrorContentProtocol
}

struct WalletErrorContent: WalletErrorContentProtocol {
    let title: String
    let message: String
}
