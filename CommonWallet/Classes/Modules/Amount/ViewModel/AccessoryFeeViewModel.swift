/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation

protocol AccessoryFeeViewModelProtocol {
    var title: String { get }
    var details: String { get }
}

struct AccessoryFeeViewModel: AccessoryFeeViewModelProtocol {
    let title: String
    let details: String
}
