import Foundation

protocol AccessoryFeeViewModelProtocol {
    var title: String { get }
    var details: String { get }
}

struct AccessoryFeeViewModel: AccessoryFeeViewModelProtocol {
    let title: String
    let details: String
}
