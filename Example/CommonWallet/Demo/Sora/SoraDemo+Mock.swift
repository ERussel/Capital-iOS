/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation
import CommonWallet

extension SoraDemo {
    private func defaultFilter(for assets: [WalletAsset]) throws -> Data {
        let filter = WalletHistoryRequest(assets: assets.map { $0.identifier })
        let encoder = JSONEncoder()

        return try encoder.encode(filter)
    }

    func mock(networkResolver: WalletNetworkResolverProtocol, with assets: [WalletAsset]) throws {
        NetworkMockManager.shared.enable()

        try SoraFetchBalanceMock.register(mock: .success,
                                          networkResolver: networkResolver,
                                          requestType: .balance,
                                          httpMethod: .post)

        try SoraFetchHistoryMock.register(mock: .success,
                                          networkResolver: networkResolver,
                                          requestType: .history,
                                          httpMethod: .post,
                                          urlMockType: .regex,
                                          body: nil)

        try SoraTransferMetadataMock.register(mock: .success,
                                              networkResolver: networkResolver,
                                              requestType: .transferMetadata,
                                              httpMethod: .get,
                                              urlMockType: .regex)

        try SoraTransferMock.register(mock: .success,
                                      networkResolver: networkResolver,
                                      requestType: .transfer,
                                      httpMethod: .post)

        try SoraSearchMock.register(mock: .success,
                                    networkResolver: networkResolver,
                                    requestType: .search,
                                    httpMethod: .get,
                                    urlMockType: .regex)

        try SoraContactsMock.register(mock: .success,
                                      networkResolver: networkResolver,
                                      requestType: .contacts,
                                      httpMethod: .get)

        try SoraWithdrawalMetadataMock.register(mock: .success,
                                                networkResolver: networkResolver,
                                                requestType: .withdrawalMetadata,
                                                httpMethod: .get,
                                                urlMockType: .regex)

        try SoraWithdrawMock.register(mock: .success,
                                      networkResolver: networkResolver,
                                      requestType: .withdraw,
                                      httpMethod: .post)
    }
}
