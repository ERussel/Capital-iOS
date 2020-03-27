/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import XCTest
@testable import CommonWallet
import Cuckoo
import RobinHood
import SoraFoundation

class ContactsTests: NetworkBaseTests {

    func testSearchSuccess() throws {
        // given

        let view = MockContactsViewProtocol()
        let networkResolver = MockNetworkResolver()

        let presenter = try performSetup(for: view, networkResolver: networkResolver)

        // when

        let completedExpectation = XCTestExpectation()
        let startSearchExpectation = XCTestExpectation()
        let stopSearchExpectation = XCTestExpectation()

        stub(view) { stub in
            when(stub).set(viewModel: any(ContactListViewModelProtocol.self)).then { _ in
                completedExpectation.fulfill()
            }

            when(stub).didStartSearch().then {
                startSearchExpectation.fulfill()
            }

            when(stub).didStopSearch().then {
                stopSearchExpectation.fulfill()
            }
        }

        try SearchMock.register(mock: .success,
                                networkResolver: networkResolver,
                                requestType: .search,
                                httpMethod: .get,
                                urlMockType: .regex)

        presenter.search("Search")

        // then

        wait(for: [completedExpectation, startSearchExpectation, stopSearchExpectation], timeout: Constants.networkTimeout)
    }

    func testSearchFailure() throws {
        // given

        let view = MockContactsViewProtocol()
        let networkResolver = MockErrorHandlingNetworkResolver()

        let presenter = try performSetup(for: view, networkResolver: networkResolver)

        // when

        let completedExpectation = XCTestExpectation()
        let startSearchExpectation = XCTestExpectation()
        let stopSearchExpectation = XCTestExpectation()

        stub(view) { stub in
            when(stub).showAlert(title: any(), message: any(), actions: any(), completion: any()).then { _ in
                completedExpectation.fulfill()
            }

            when(stub).didStartSearch().then {
                startSearchExpectation.fulfill()
            }

            when(stub).didStopSearch().then {
                stopSearchExpectation.fulfill()
            }
        }

        try SearchMock.register(mock: .error,
                                networkResolver: networkResolver,
                                requestType: .search,
                                httpMethod: .get,
                                urlMockType: .regex)

        presenter.search("Search")

        // then

        wait(for: [completedExpectation, startSearchExpectation, stopSearchExpectation], timeout: Constants.networkTimeout)
    }

    // MARK: Private

    private func performSetup(for view: MockContactsViewProtocol,
                              networkResolver: WalletNetworkResolverProtocol) throws -> ContactsPresenterProtocol {
        let accountSettings = try createRandomAccountSettings(for: 1)

        let cacheFacade = CoreDataTestCacheFacade()

        let networkOperationFactory = MiddlewareOperationFactory(accountSettings: accountSettings,
                                                                 networkResolver: networkResolver)

        let dataProviderFactory = DataProviderFactory(accountSettings: accountSettings,
                                                      cacheFacade: cacheFacade,
                                                      networkOperationFactory: networkOperationFactory)
        let dataProvider = try dataProviderFactory.createContactsDataProvider()

        let walletService = WalletService(operationFactory: networkOperationFactory)

        let contactsConfiguration = ContactsModuleBuilder().build()

        let commandFactory = createMockedCommandFactory()

        let viewModelFactory = ContactsViewModelFactory(configuration: contactsConfiguration, avatarRadius: 10.0, commandFactory: commandFactory)

        let coordinator = MockContactsCoordinatorProtocol()

        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 3

        try ContactsMock.register(mock: .success,
                                  networkResolver: networkResolver,
                                  requestType: .contacts,
                                  httpMethod: .get)

        stub(view) { stub in
            when(stub).set(viewModel: any(ContactListViewModelProtocol.self)).then { viewModel in
                expectation.fulfill()
            }

            when(stub).isSetup.get.thenReturn(false, true)
        }

        let presenter = ContactsPresenter(view: view,
                                          coordinator: coordinator,
                                          dataProvider: dataProvider,
                                          walletService: walletService,
                                          viewModelFactory: viewModelFactory,
                                          selectedAsset: accountSettings.assets[0],
                                          currentAccountId: accountSettings.accountId,
                                          withdrawOptions: [])

        presenter.localizationManager = LocalizationManager(localization: WalletLanguage.english.rawValue)

        presenter.setup()

        wait(for: [expectation], timeout: Constants.networkTimeout)

        XCTAssertTrue(presenter.viewModel.contacts.count > 0)

        return presenter
    }
}
