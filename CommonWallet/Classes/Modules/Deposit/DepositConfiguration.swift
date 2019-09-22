import Foundation

protocol DepositConfigurationProtocol {
    var viewModelFactory: DepositViewModelFactoryProtocol { get }
}

struct DepositConfiguration: DepositConfigurationProtocol {
    let viewModelFactory: DepositViewModelFactoryProtocol
}
