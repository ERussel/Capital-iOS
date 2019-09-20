import Foundation

public struct FeeData: Codable, Equatable {
    public let assetId: String
    public let type: String
    public let parameters: [String]
    public let accountId: String?

    public init(assetId: String, type: String, parameters: [String], accountId: String? = nil) {
        self.assetId = assetId
        self.type = type
        self.parameters = parameters
        self.accountId = accountId
    }

    var decimalParameters: [Decimal]? {
        var decimals: [Decimal] = []

        for parameter in parameters {
            if let decimalParameter = Decimal(string: parameter) {
                decimals.append(decimalParameter)
            } else {
                return nil
            }
        }

        return decimals
    }
}
