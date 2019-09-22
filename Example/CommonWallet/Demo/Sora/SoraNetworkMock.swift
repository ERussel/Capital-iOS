/**
 * Copyright Soramitsu Co., Ltd. All Rights Reserved.
 * SPDX-License-Identifier: GPL-3.0
 */

import Foundation

enum SoraFetchBalanceMock: ServiceMockProtocol {
    case success

    var mockFile: String {
        return "soraAccounBalanceResponse.json"
    }
}

enum SoraFetchHistoryMock: ServiceMockProtocol {
    case success

    var mockFile: String {
        return "soraHistoryResponse.json"
    }
}

enum SoraSearchMock: ServiceMockProtocol {
    case success

    var mockFile: String {
        return "soraSearchResponse.json"
    }
}

enum SoraTransferMetadataMock: ServiceMockProtocol {
    case success

    var mockFile: String {
        return "soraTransferMetadataResponse.json"
    }
}

enum SoraTransferMock: ServiceMockProtocol {
    case success

    var mockFile: String {
        return "successResultResponse.json"
    }
}

enum SoraContactsMock: ServiceMockProtocol {
    case success

    var mockFile: String {
        return "soraContactsResponse.json"
    }
}

enum SoraWithdrawalMetadataMock: ServiceMockProtocol {
    case success

    var mockFile: String {
        return "soraWithdrawalMetadataResponse.json"
    }
}

enum SoraWithdrawMock: ServiceMockProtocol {
    case success

    var mockFile: String {
        return "successResultResponse.json"
    }
}
