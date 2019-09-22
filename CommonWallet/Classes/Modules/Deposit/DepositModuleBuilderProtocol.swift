import Foundation

public protocol DepositModuleBuilderProtocol: class {
    @discardableResult
    func with(viewModelFactory: DepositViewModelFactoryProtocol) -> Self
}

enum DepositModuleBuilderError: Error {
    case missingViewModelFactory
}

final class DepositModuleBuilder {
    var viewModelFactory: DepositViewModelFactoryProtocol?

    func build() throws -> DepositConfigurationProtocol {
        guard let viewModelFactory = viewModelFactory else {
            throw DepositModuleBuilderError.missingViewModelFactory
        }

        return DepositConfiguration(viewModelFactory: viewModelFactory)
    }
}

extension DepositModuleBuilder: DepositModuleBuilderProtocol {
    @discardableResult
    func with(viewModelFactory: DepositViewModelFactoryProtocol) -> Self {
        self.viewModelFactory = viewModelFactory

        return self
    }
}
