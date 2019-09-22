/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import UIKit
import SoraUI

final class DepositViewController: UIViewController, AdaptiveDesignable {
    var presenter: DepositPresenterProtocol!

    var style: WalletStyleProtocol?

    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var qrImageView: UIImageView!
    @IBOutlet private var optionControl: ActionTitleControl!
    @IBOutlet private var qrSeparatorView: BorderedContainerView!
    @IBOutlet private var stepContainerView: StepContainerView!

    @IBOutlet private var qrBackgroundHeight: NSLayoutConstraint!
    @IBOutlet private var qrHeight: NSLayoutConstraint!
    @IBOutlet private var qrWidth: NSLayoutConstraint!

    private var assetSelectionViewModel: AssetSelectionViewModelProtocol?

    private var didCompleteSetup: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        configureStyle()

        adjustConstraints()

        let size = CGSize(width: qrWidth.constant, height: qrHeight.constant)
        presenter.setup(qrSize: size)
    }

    override func viewWillLayoutSubviews() {
        stepContainerView.invalidateIntrinsicContentSize()

        super.viewWillLayoutSubviews()
    }

    private func adjustConstraints() {
        qrWidth.constant *= designScaleRatio.width
        qrHeight.constant *= designScaleRatio.width
        qrBackgroundHeight.constant *= designScaleRatio.width
    }

    private func configureStyle() {
        if let style = style {
            view.backgroundColor = style.backgroundColor

            qrSeparatorView.strokeColor = style.thickBorderColor

            optionControl.titleLabel.textColor = style.bodyTextColor
            optionControl.titleLabel.font = style.bodyRegularFont
            optionControl.imageView.image = style.downArrowIcon
        }
    }

    override var navigationItem: UINavigationItem {
        let navigationItem = super.navigationItem

        let shareItem = UIBarButtonItem(image: style?.shareIcon,
                                        style: .plain,
                                        target: self,
                                        action: #selector(actionShare))

        let closeItem = UIBarButtonItem(image: style?.closeIcon,
                                        style: .plain,
                                        target: self,
                                        action: #selector(actionClose))

        navigationItem.leftBarButtonItem = closeItem
        navigationItem.rightBarButtonItem = shareItem

        return navigationItem
    }

    @IBAction private func actionOption() {
        presenter.presentOptionsSelection()
    }

    @objc private func actionClose() {
        presenter.close()
    }

    @objc private func actionShare() {
        presenter.share()
    }
}

extension DepositViewController: DepositViewProtocol {
    func set(qrImage: UIImage) {
        qrImageView.image = qrImage
    }

    func set(assetSelectionViewModel: AssetSelectionViewModelProtocol) {
        self.assetSelectionViewModel?.observable.remove(observer: self)

        self.assetSelectionViewModel = assetSelectionViewModel
        assetSelectionViewModel.observable.add(observer: self)

        optionControl.titleLabel.text = assetSelectionViewModel.title
        optionControl.isUserInteractionEnabled = assetSelectionViewModel.canSelect
        optionControl.imageView.image = assetSelectionViewModel.canSelect ? style?.downArrowIcon : nil
        optionControl.invalidateLayout()

        optionControl.isUserInteractionEnabled = assetSelectionViewModel.canSelect
    }

    func set(steps: [StepViewModel]) {
        stepContainerView.bind(viewModels: steps)

        scrollView.setNeedsLayout()
    }
}

extension DepositViewController: AssetSelectionViewModelObserver {
    func assetSelectionDidChangeSymbol() {}

    func assetSelectionDidChangeTitle() {
        optionControl.titleLabel.text = assetSelectionViewModel?.title
    }

    func assetSelectionDidChangeState() {
        guard let assetSelectionViewModel = assetSelectionViewModel else {
            return
        }

        if assetSelectionViewModel.isSelecting {
            optionControl.activate(animated: true)
        } else {
            optionControl.deactivate(animated: true)
        }
    }


}
