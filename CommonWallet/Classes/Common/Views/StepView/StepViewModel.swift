/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation

public struct StepViewModel {
    public let index: Int
    public let title: String

    public init(index: Int, title: String) {
        self.index = index
        self.title = title
    }
}
