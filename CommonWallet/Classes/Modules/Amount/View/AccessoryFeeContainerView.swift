import UIKit

final class AccessoryFeeContainerView: UIView {
    private var feeViews: [AccessoryFeeView] = []

    var style: WalletStyleProtocol? {
        didSet {
            applyStyle()
        }
    }

    override var intrinsicContentSize: CGSize {
        let totalHeight = feeViews.reduce(CGFloat(0.0)) { (result, view) in
            guard let height = view.constraints
                .first(where: {$0.firstAttribute == .height} )?.constant else {
                return result
            }

            return result + height
        }

        return CGSize(width: UIView.noIntrinsicMetric, height: totalHeight)
    }

    func bind(viewModels: [AccessoryFeeViewModelProtocol]) {
        if feeViews.count > viewModels.count {
            removeFeeViews(count: feeViews.count - viewModels.count)
        } else if feeViews.count < viewModels.count {
            addFeeViews(count: viewModels.count - feeViews.count)
        }

        for (index, viewModel) in viewModels.enumerated() {
            feeViews[index].bind(viewModel: viewModel)
        }

        applyStyle()

        invalidateIntrinsicContentSize()

        setNeedsLayout()
    }

    private func removeFeeViews(count: Int) {
        (0..<count).forEach { _ in
            let feeView = feeViews.removeLast()
            feeView.removeFromSuperview()
        }
    }

    private func addFeeViews(count: Int) {
        for _ in 0..<count {
            guard let feeView = createNewFeeView() else {
                return
            }

            feeView.translatesAutoresizingMaskIntoConstraints = false

            addSubview(feeView)

            feeView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            feeView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true

            if let lastView = feeViews.last {
                feeView.topAnchor.constraint(equalTo: lastView.bottomAnchor).isActive = true
            } else {
                feeView.topAnchor.constraint(equalTo: topAnchor).isActive = true
            }

            feeView.heightAnchor.constraint(equalToConstant: feeView.frame.height)
        }
    }

    private func createNewFeeView() -> AccessoryFeeView? {
        return UINib(nibName: "AccessoryFeeView", bundle: Bundle(for: type(of: self)))
            .instantiate(withOwner: nil, options: nil).first as? AccessoryFeeView
    }

    private func applyStyle() {
        if let style = style {
            feeViews.forEach { $0.apply(style: style) }
        }
    }
}
