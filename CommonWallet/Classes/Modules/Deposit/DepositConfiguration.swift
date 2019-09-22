/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation

protocol DepositConfigurationProtocol {
    var viewModelFactory: DepositViewModelFactoryProtocol { get }
}

struct DepositConfiguration: DepositConfigurationProtocol {
    let viewModelFactory: DepositViewModelFactoryProtocol
}
