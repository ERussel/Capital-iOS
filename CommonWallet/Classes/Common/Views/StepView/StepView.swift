import UIKit
import SoraUI

final class StepView: UIView {
    @IBOutlet private var stepIndexView: RoundedButton!
    @IBOutlet private var titleLabel: UILabel!

    override var intrinsicContentSize: CGSize {
        let indexHeight = stepIndexView.constraints
            .first(where: { $0.firstAttribute == .height})?.constant ?? 0.0

        let height = max(indexHeight, titleLabel.intrinsicContentSize.height)

        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }

    func bind(viewModel: StepViewModel) {
        stepIndexView.imageWithTitleView?.title = "\(viewModel.index)"
        stepIndexView.invalidateLayout()

        titleLabel.text = viewModel.title

        invalidateIntrinsicContentSize()

        setNeedsLayout()
    }
}
