import UIKit

final class StepContainerView: UIView {
    private var views: [StepView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)

        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        configure()
    }

    var spacing: CGFloat = 8.0

    override var intrinsicContentSize: CGSize {
        var totalHeight = views.reduce(CGFloat(0.0)) { (result, view) in
            return result + view.intrinsicContentSize.height
        }

        totalHeight += CGFloat(views.count - 1) * spacing

        return CGSize(width: UIView.noIntrinsicMetric, height: totalHeight)
    }

    override func invalidateIntrinsicContentSize() {
        super.invalidateIntrinsicContentSize()

        views.forEach { $0.invalidateIntrinsicContentSize() }
    }

    private func configure() {
        backgroundColor = UIColor.clear
    }

    func bind(viewModels: [StepViewModel]) {
        if views.count > viewModels.count {
            removeViews(count: views.count - viewModels.count)
        } else if views.count < viewModels.count {
            addViews(count: viewModels.count - views.count)
        }

        for (index, viewModel) in viewModels.enumerated() {
            views[index].bind(viewModel: viewModel)
        }

        invalidateIntrinsicContentSize()

        setNeedsLayout()
    }

    private func removeViews(count: Int) {
        (0..<count).forEach { _ in
            let view = views.removeLast()
            view.removeFromSuperview()
        }
    }

    private func addViews(count: Int) {
        for _ in 0..<count {
            guard let view = createNewView() else {
                return
            }

            view.translatesAutoresizingMaskIntoConstraints = false

            addSubview(view)

            view.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            view.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true

            if let lastView = views.last {
                view.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: spacing).isActive = true
            } else {
                view.topAnchor.constraint(equalTo: topAnchor).isActive = true
            }

            views.append(view)
        }
    }

    private func createNewView() -> StepView? {
        return UINib(nibName: "StepView", bundle: Bundle(for: type(of: self)))
            .instantiate(withOwner: nil, options: nil).first as? StepView
    }
}
