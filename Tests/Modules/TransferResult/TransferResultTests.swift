/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import XCTest
@testable import CommonWallet
import Cuckoo
import IrohaCommunication

class TransferResultTests: NetworkBaseTests {

    func testSetup() {
        do {
            // given

            let view = MockWalletFormViewProtocol()
            let coordinator = MockTransferResultCoordinatorProtocol()
            let resolver = MockResolverProtocol()

            let accountSettings = try createRandomAccountSettings(for: 1)

            var transferInfo = try createRandomTransferInfo()
            transferInfo.source = accountSettings.accountId

            let transferPayload = TransferPayload(transferInfo: transferInfo,
                                                  receiverName: UUID().uuidString,
                                                  assetSymbol: accountSettings.assets[0].symbol)

            let presenter = TransferResultPresenter(view: view,
                                                    coordinator: coordinator,
                                                    payload: transferPayload,
                                                    resolver: resolver,
                                                    feeInfoFactory: FeeInfoFactory())

            // when

            let mainExpectation = XCTestExpectation()
            let accessoryExpectation = XCTestExpectation()

            stub(view) { stub in
                when(stub).didReceive(viewModels: any()).then { _ in
                    mainExpectation.fulfill()
                }

                when(stub).didReceive(accessoryViewModel: any(AccessoryViewModelProtocol?.self)).then { _ in
                    accessoryExpectation.fulfill()
                }
            }

            stub(resolver) { stub in
                when(stub).amountFormatter.get.thenReturn(NumberFormatter())
                when(stub).statusDateFormatter.get.thenReturn(DateFormatter())
                when(stub).style.get.thenReturn(WalletStyle())
            }

            presenter.setup()

            // then

            wait(for: [mainExpectation, accessoryExpectation], timeout: Constants.networkTimeout)

        } catch {
            XCTFail("\(error)")
        }
    }
}
