import Foundation

final class DepositCoordinator: DepositCoordinatorProtocol {
    let resolver: ResolverProtocol

    init(resolver: ResolverProtocol) {
        self.resolver = resolver
    }

    func close() {
        resolver.navigation?.dismiss()
    }
}
