/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation


protocol ReceiveAmountConfigurationProtocol {
    var accountShareFactory: AccountShareFactoryProtocol { get }
}


struct ReceiveAmountConfiguration: ReceiveAmountConfigurationProtocol {
    var accountShareFactory: AccountShareFactoryProtocol
}
