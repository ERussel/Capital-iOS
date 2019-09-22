/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation
import SoraUI

final class AccessoryFeeView: UIView {
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var detailsLabel: UILabel!
    @IBOutlet private var separator: BorderedContainerView!

    func apply(style: WalletStyleProtocol) {
        titleLabel.textColor = style.bodyTextColor
        titleLabel.font = style.bodyRegularFont

        detailsLabel.textColor = style.captionTextColor
        detailsLabel.font = style.bodyRegularFont

        separator.strokeColor = style.thickBorderColor
    }

    func bind(viewModel: AccessoryFeeViewModelProtocol) {
        titleLabel.text = viewModel.title
        detailsLabel.text = viewModel.details
    }
}
