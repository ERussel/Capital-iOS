/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation

public enum ResultDataError: Error {
    case missingStatusField
    case unexpectedNumberOfFields
}

public struct StatusData: Decodable {
    public let code: String
    public let message: String

    public var isSuccess: Bool {
        return code == "OK"
    }

    public init(code: String, message: String) {
        self.code = code
        self.message = message
    }
}

public struct ResultData<ResultType> where ResultType: Decodable {
    public let status: StatusData
    public let result: ResultType?

    public init(status: StatusData, result: ResultType?) {
        self.status = status
        self.result = result
    }
}

extension ResultData: Decodable {
    enum CodingKeys: String, CodingKey {
        case status
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)

        guard container.allKeys.count > 0, container.allKeys.count < 3 else {
            throw ResultDataError.unexpectedNumberOfFields
        }

        guard let statusKey = DynamicCodingKey(stringValue: CodingKeys.status.rawValue) else {
            throw ResultDataError.missingStatusField
        }

        status = try container.decode(StatusData.self, forKey: statusKey)

        if let resultKey = container.allKeys.first(where: { $0.stringValue != CodingKeys.status.stringValue }) {
            result = try container.decode(ResultType.self, forKey: resultKey)
        } else {
            result = nil
        }
    }
}

public struct MultifieldResultData<ResultType> where ResultType: Decodable {
    public let status: StatusData
    public let result: ResultType

    public init(status: StatusData, result: ResultType) {
        self.status = status
        self.result = result
    }
}

extension MultifieldResultData: Decodable {
    enum CodingKeys: String, CodingKey {
        case status
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)

        guard let statusKey = DynamicCodingKey(stringValue: CodingKeys.status.rawValue) else {
            throw ResultDataError.missingStatusField
        }

        status = try container.decode(StatusData.self, forKey: statusKey)

        result = try ResultType(from: decoder)
    }
}
