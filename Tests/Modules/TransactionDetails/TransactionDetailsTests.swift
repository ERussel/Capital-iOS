/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import XCTest
@testable import CommonWallet
import Cuckoo
import IrohaCommunication

class TransactionDetailsTests: XCTestCase {

    func testSetup() {
        do {
            // given

            let accountSettings = try createRandomAccountSettings(for: 1)

            let view = MockWalletFormViewProtocol()
            let coordinator = MockTransactionDetailsCoordinatorProtocol()

            let resolver = MockResolverProtocol()

            stub(resolver) { stub in
                when(stub).amountFormatter.get.thenReturn(NumberFormatter())
                when(stub).statusDateFormatter.get.thenReturn(DateFormatter())
                when(stub).style.get.thenReturn(WalletStyle())
                when(stub).account.get.thenReturn(accountSettings)
            }

            let transactionData = try createRandomAssetTransactionData()
            let transactionType: WalletTransactionType

            if transactionData.type == WalletTransactionType.incoming.backendName {
                transactionType = WalletTransactionType.incoming
            } else {
                transactionType = WalletTransactionType.outgoing
            }

            let accessoryViewModelFactory = ContactAccessoryViewModelFactory(style: resolver.style.nameIconStyle,
                                                                             radius: AccessoryView.iconRadius)

            let configuration = TransactionDetailsConfiguration(sendBackTransactionTypes: [])
            let presenter = TransactionDetailsPresenter(view: view,
                                                        coordinator: coordinator,
                                                        configuration:  configuration,
                                                        resolver: resolver,
                                                        transactionData: transactionData,
                                                        transactionType: transactionType,
                                                        accessoryViewModelFactory: accessoryViewModelFactory,
                                                        feeInfoFactory: FeeInfoFactory())

            // when

            let listExpectation = XCTestExpectation()

            stub(view) { stub in
                when(stub).didReceive(viewModels: any()).then { _ in
                    listExpectation.fulfill()
                }

                when(stub).didReceive(accessoryViewModel: any()).thenDoNothing()
            }

            presenter.setup()

            // then

            wait(for: [listExpectation], timeout: Constants.networkTimeout)
        } catch {
            XCTFail("\(error)")
        }
    }
}
