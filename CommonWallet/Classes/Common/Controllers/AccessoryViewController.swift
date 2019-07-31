/**
 * Copyright Soramitsu Co., Ltd. All Rights Reserved.
 * SPDX-License-Identifier: GPL-3.0
 */

import UIKit

class AccessoryViewController: UIViewController {
    var shouldSetupKeyboardHandler: Bool = true
    var accessoryViewFactory: AccessoryViewFactoryProtocol.Type = AccessoryViewFactory.self
    var accessoryStyle: WalletAccessoryStyleProtocol?

    private(set) var accessoryView: AccessoryViewProtocol?
    private(set) var keyboardHandler: KeyboardHandler?
    private(set) var bottomConstraint: NSLayoutConstraint?

    private var isFirstLayoutCompleted: Bool = false
    private var keyboardFrameOnFirstLayout: CGRect?

    override func viewDidLoad() {
        super.viewDidLoad()

        configureAccessoryView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if shouldSetupKeyboardHandler {
            setupKeyboardHandler()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        clearKeyboardHandler()
    }

    override func viewDidLayoutSubviews() {
        guard !isFirstLayoutCompleted else {
            return
        }

        if let keyboardFrame = keyboardFrameOnFirstLayout {
            apply(keyboardFrame: keyboardFrame)
        }

        isFirstLayoutCompleted = true

        super.viewDidLayoutSubviews()
    }

    func configureAccessoryView() {
        let accessoryView = accessoryViewFactory.createAccessoryView(from: accessoryStyle,
                                                                     target: self,
                                                                     completionSelector: #selector(actionAccessory))
        view.addSubview(accessoryView.contentView)
        self.accessoryView = accessoryView

        accessoryView.contentView.translatesAutoresizingMaskIntoConstraints = false

        accessoryView.contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        accessoryView.contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

        let height = accessoryView.contentView.frame.height
        accessoryView.contentView.heightAnchor.constraint(equalToConstant: height).isActive = true

        if #available(iOS 11.0, *) {
            bottomConstraint = accessoryView.contentView.bottomAnchor
                .constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0.0)
        } else {
            bottomConstraint = accessoryView.contentView.bottomAnchor
                .constraint(equalTo: view.bottomAnchor, constant: 0.0)
        }

        bottomConstraint?.isActive = true
    }

    // MARK: Keyboard

    private func setupKeyboardHandler() {
        guard keyboardHandler == nil else {
            return
        }

        keyboardHandler = KeyboardHandler(with: nil)
        keyboardHandler?.animateOnFrameChange = { [weak self] keyboardFrame in
            self?.animateKeyboardBoundsChange(for: keyboardFrame)
        }
    }

    private func clearKeyboardHandler() {
        keyboardHandler = nil
    }

    private func animateKeyboardBoundsChange(for keyboardFrame: CGRect) {
        guard isFirstLayoutCompleted else {
            keyboardFrameOnFirstLayout = keyboardFrame
            return
        }

        apply(keyboardFrame: keyboardFrame)

        view.layoutIfNeeded()
    }

    private func apply(keyboardFrame: CGRect) {
        let localKeyboardFrame = view.convert(keyboardFrame, from: nil)
        var bottomInset = view.bounds.height - localKeyboardFrame.minY

        if #available(iOS 11.0, *) {
            bottomInset -= view.safeAreaInsets.bottom
        }

        bottomInset = max(bottomInset, 0.0)
        bottomConstraint?.constant = -bottomInset

        if let accessoryView = accessoryView {
            updateBottom(inset: bottomInset + accessoryView.contentView.frame.size.height)
        }
    }

    // MARK: Overridable methods

    func updateBottom(inset: CGFloat) {}

    @objc func actionAccessory() {}
}
