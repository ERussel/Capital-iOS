/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import UIKit
import AVFoundation
import SoraUI


final class InvoiceScanViewController: UIViewController, AdaptiveDesignable {
    var presenter: InvoiceScanPresenterProtocol!

    var style: InvoiceScanViewStyleProtocol?

    @IBOutlet private var qrFrameView: CameraFrameView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var messageLabel: UILabel!

    @IBOutlet private var titleTop: NSLayoutConstraint!
    @IBOutlet private var titleLeading: NSLayoutConstraint!
    @IBOutlet private var titleTralling: NSLayoutConstraint!
    @IBOutlet private var messageBottom: NSLayoutConstraint!
    @IBOutlet private var messageLeading: NSLayoutConstraint!
    @IBOutlet private var messageTralling: NSLayoutConstraint!

    lazy var messageAppearanceAnimator: BlockViewAnimatorProtocol = BlockViewAnimator()
    lazy var messageDissmisAnimator: BlockViewAnimatorProtocol = BlockViewAnimator()

    var messageVisibilityDuration: TimeInterval = 5.0

    deinit {
        invalidateMessageScheduling()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureStyle()
        adjustLayout()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        presenter.prepareDismiss()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        presenter.prepareAppearance()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        presenter.handleDismiss()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        presenter.handleAppearance()
    }

    func configureStyle() {
        if let style = style {
            titleLabel.textColor = style.title.color
            titleLabel.font = style.title.font

            messageLabel.textColor = style.message.color
            messageLabel.font = style.message.font

            qrFrameView.fillColor = style.background
        }
    }

    private func adjustLayout() {
        titleTop.constant *= designScaleRatio.width
        titleLeading.constant *= designScaleRatio.width
        titleTralling.constant *= designScaleRatio.width

        messageLeading.constant *= designScaleRatio.width
        messageTralling.constant *= designScaleRatio.width

        if isAdaptiveHeightDecreased {
            messageBottom.constant *= designScaleRatio.height
        }

        var windowSize = qrFrameView.windowSize
        windowSize.width *= designScaleRatio.width
        windowSize.height *= designScaleRatio.width
        qrFrameView.windowSize = windowSize
    }

    private func configureVideoLayer(with captureSession: AVCaptureSession) {
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer.frame = view.layer.bounds

        qrFrameView.frameLayer = videoPreviewLayer
    }

    // MARK: Message Management

    private func scheduleMessageHide() {
        invalidateMessageScheduling()

        perform(#selector(hideMessage), with: true, afterDelay: messageVisibilityDuration)
    }

    private func invalidateMessageScheduling() {
        NSObject.cancelPreviousPerformRequests(withTarget: self,
                                               selector: #selector(hideMessage),
                                               object: true)
    }

    @objc private func hideMessage() {
        let block: () -> Void = { [weak self] in
            self?.messageLabel.alpha = 0.0
        }

        messageDissmisAnimator.animate(block: block, completionBlock: nil)
    }
}

extension InvoiceScanViewController: InvoiceScanViewProtocol {
    func didReceive(session: AVCaptureSession) {
        configureVideoLayer(with: session)
    }

    func present(message: String, animated: Bool) {
        messageLabel.text = message

        let block: () -> Void = { [weak self] in
            self?.messageLabel.alpha = 1.0
        }

        if animated {
            messageAppearanceAnimator.animate(block: block, completionBlock: nil)
        } else {
            block()
        }

        scheduleMessageHide()
    }
}