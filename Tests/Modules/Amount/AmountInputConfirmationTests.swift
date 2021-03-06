/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import XCTest
@testable import CommonWallet
import Cuckoo
import IrohaCommunication
import SoraFoundation

class AmountInputConfirmationTests: NetworkBaseTests {

    func testSuccessfullAmountInput() {
        let networkResolver = MockNetworkResolver()

        performConfirmationTest(for: networkResolver,
                                transactionSettingsFactory: WalletTransactionSettingsFactory(),
                                inputAmount: "100",
                                inputDescription: "",
                                expectsSuccess: true)

        performConfirmationTest(for: networkResolver,
                                transactionSettingsFactory: WalletTransactionSettingsFactory(),
                                inputAmount: "100",
                                inputDescription: "Description",
                                expectsSuccess: true)
    }

    func testUnsufficientFundsInput() {
        let networkResolver = MockNetworkResolver()

        performConfirmationTest(for: networkResolver,
                                transactionSettingsFactory: WalletTransactionSettingsFactory(),
                                inputAmount: "100000",
                                inputDescription: "",
                                expectsSuccess: false)
    }

    func testMinimumAmountInput() {
        let networkResolver = MockNetworkResolver()

        let settingsMock = MockWalletTransactionSettingsFactoryProtocol()

        stub(settingsMock) { stub in
            when(stub).createSettings(for: any(), senderId: any(), receiverId: any()).then { _ in
                WalletTransactionSettings(transferLimit: WalletTransactionLimit(minimum: 10, maximum: 1e+6),
                                          withdrawLimit: WalletTransactionLimit(minimum: 0, maximum: 1e+6))
            }
        }

        performConfirmationTest(for: networkResolver,
                                transactionSettingsFactory: settingsMock,
                                inputAmount: "1",
                                inputDescription: "",
                                expectsSuccess: false)
    }

    func testFixedFeeTransfer() {
        let networkResolver = MockNetworkResolver()

        let settingsMock = MockWalletTransactionSettingsFactoryProtocol()

        stub(settingsMock) { stub in
            when(stub).createSettings(for: any(), senderId: any(), receiverId: any()).then { _ in
                WalletTransactionSettings(transferLimit: WalletTransactionLimit(minimum: 0, maximum: 1e+6),
                                          withdrawLimit: WalletTransactionLimit(minimum: 0, maximum: 1e+6))
            }
        }

        performConfirmationTest(for: networkResolver,
                                transactionSettingsFactory: settingsMock,
                                inputAmount: "100",
                                inputDescription: "",
                                expectsSuccess: true,
                                metadataMock: .fixed,
                                expectedAmount: Decimal(string: "100")!,
                                expectedFee: Decimal(string: "1.0")!)
    }

    func testFactorFeeTransfer() {
        let networkResolver = MockNetworkResolver()

        let settingsMock = MockWalletTransactionSettingsFactoryProtocol()

        stub(settingsMock) { stub in
            when(stub).createSettings(for: any(), senderId: any(), receiverId: any()).then { _ in
                WalletTransactionSettings(transferLimit: WalletTransactionLimit(minimum: 0, maximum: 1e+6),
                                          withdrawLimit: WalletTransactionLimit(minimum: 0, maximum: 1e+6))
            }
        }

        performConfirmationTest(for: networkResolver,
                                transactionSettingsFactory: settingsMock,
                                inputAmount: "90",
                                inputDescription: "",
                                expectsSuccess: true,
                                metadataMock: .factor,
                                expectedAmount: Decimal(string: "90")!,
                                expectedFee: Decimal(string: "0.9")!)
    }

    func testTaxFeeTransfer() {
        let networkResolver = MockNetworkResolver()

        let settingsMock = MockWalletTransactionSettingsFactoryProtocol()

        stub(settingsMock) { stub in
            when(stub).createSettings(for: any(), senderId: any(), receiverId: any()).then { _ in
                WalletTransactionSettings(transferLimit: WalletTransactionLimit(minimum: 0, maximum: 1e+6),
                                          withdrawLimit: WalletTransactionLimit(minimum: 0, maximum: 1e+6))
            }
        }

        performConfirmationTest(for: networkResolver,
                                transactionSettingsFactory: settingsMock,
                                inputAmount: "80",
                                inputDescription: "",
                                expectsSuccess: true,
                                metadataMock: .tax,
                                expectedAmount: Decimal(string: "72")!,
                                expectedFee: Decimal(string: "8")!)
    }

    // MARK: Private

    private func performConfirmationTest(for networkResolver: WalletNetworkResolverProtocol,
                                         transactionSettingsFactory: WalletTransactionSettingsFactoryProtocol,
                                         inputAmount: String,
                                         inputDescription: String,
                                         expectsSuccess: Bool,
                                         metadataMock: TransferMetadataMock = .success,
                                         expectedAmount: Decimal? = nil,
                                         expectedFee: Decimal? = nil,
                                         beforeConfirmationBlock: (() -> Void)? = nil) {
        do {
            // given

            let assetId = try IRAssetIdFactory.asset(withIdentifier: Constants.soraAssetId)
            let walletAsset = WalletAsset(identifier: assetId,
                                          symbol: "A",
                                          details: LocalizableResource { _ in UUID().uuidString },
                                          precision: 2)
            let accountSettings = try createRandomAccountSettings(for: [walletAsset],
                                                                  withdrawOptions: [])

            let cacheFacade = CoreDataTestCacheFacade()

            let networkOperationFactory = MiddlewareOperationFactory(accountSettings: accountSettings,
                                                                     networkResolver: networkResolver)

            let dataProviderFactory = DataProviderFactory(accountSettings: accountSettings,
                                                          cacheFacade: cacheFacade,
                                                          networkOperationFactory: networkOperationFactory)

            let assetSelectionFactory = AssetSelectionFactory(amountFormatterFactory: NumberFormatterFactory())
            let accessoryViewModelFactory = ContactAccessoryViewModelFactory(style: WalletStyle().nameIconStyle,
                                                                             radius: AccessoryView.iconRadius)

            let view = MockAmountViewProtocol()
            let coordinator = MockAmountCoordinatorProtocol()

            let assetSelectionObserver = MockAssetSelectionViewModelObserver()
            let feeViewModelObserver = MockFeeViewModelObserver()

            try FetchBalanceMock.register(mock: .success,
                                          networkResolver: networkResolver,
                                          requestType: .balance,
                                          httpMethod: .post)

            try TransferMetadataMock.register(mock: metadataMock,
                                              networkResolver: networkResolver,
                                              requestType: .transferMetadata,
                                              httpMethod: .get,
                                              urlMockType: .regex)

            // when

            let titleExpectation = XCTestExpectation()
            let assetExpectation = XCTestExpectation()
            let amountExpectation = XCTestExpectation()
            let feeExpectation = XCTestExpectation()
            let descriptionExpectation = XCTestExpectation()
            let errorExpectation = XCTestExpectation()
            let accessoryExpectation = XCTestExpectation()

            let balanceExpectation = XCTestExpectation()
            let feeLoadedExpectation = XCTestExpectation()
            feeLoadedExpectation.expectedFulfillmentCount = 2

            var amountViewModel: AmountInputViewModelProtocol?
            var descriptionViewModel: DescriptionInputViewModelProtocol?

            stub(view) { stub in
                when(stub).set(title: any(String.self)).then { _ in
                    titleExpectation.fulfill()
                }

                when(stub).set(assetViewModel: any()).then { assetViewModel in
                    assetViewModel.observable.add(observer: assetSelectionObserver)
                    assetExpectation.fulfill()
                }

                when(stub).set(amountViewModel: any()).then { viewModel in
                    amountViewModel = viewModel

                    amountExpectation.fulfill()
                }

                when(stub).set(feeViewModel: any()).then { viewModel in
                    viewModel.observable.add(observer: feeViewModelObserver)

                    feeExpectation.fulfill()
                }

                when(stub).set(descriptionViewModel: any()).then { viewModel in
                    descriptionViewModel = viewModel

                    descriptionExpectation.fulfill()
                }

                when(stub).set(accessoryViewModel: any()).then { _ in
                    accessoryExpectation.fulfill()
                }

                when(stub).showAlert(title: any(), message: any(), actions: any(), completion: any()).then { _ in
                    errorExpectation.fulfill()
                }

                when(stub).didStartLoading().thenDoNothing()
                when(stub).didStopLoading().thenDoNothing()

                when(stub).controller.get.thenReturn(UIViewController())

                when(stub).isSetup.get.thenReturn(false, true)
            }

            stub(assetSelectionObserver) { stub in
                when(stub).assetSelectionDidChangeTitle().then { title in
                    balanceExpectation.fulfill()
                }
            }

            stub(feeViewModelObserver) { stub in
                when(stub).feeTitleDidChange().thenDoNothing()

                when(stub).feeLoadingStateDidChange().then {
                    feeLoadedExpectation.fulfill()
                }
            }

            let confirmExpectation = XCTestExpectation()

            var payloadToConfirm: TransferPayload?

            stub(coordinator) { stub in
                when(stub).confirm(with: any(TransferPayload.self)).then { payload in
                    payloadToConfirm = payload

                    confirmExpectation.fulfill()
                }
            }

            var recieverInfo = try createRandomReceiveInfo()
            recieverInfo.amount = nil

            let amountPayload = AmountPayload(receiveInfo: recieverInfo, receiverName: UUID().uuidString)

            let inputValidatorFactory = WalletInputValidatorFactoryDecorator(descriptionMaxLength: 64)
            let transferViewModelFactory = AmountViewModelFactory(amountFormatterFactory: NumberFormatterFactory(),
                                                                  descriptionValidatorFactory: inputValidatorFactory,
                                                                  transactionSettingsFactory: transactionSettingsFactory,
                                                                  feeDisplaySettingsFactory: FeeDisplaySettingsFactory())

            let presenter = try AmountPresenter(view: view,
                                                coordinator: coordinator,
                                                payload: amountPayload,
                                                dataProviderFactory: dataProviderFactory,
                                                feeCalculationFactory: FeeCalculationFactory(),
                                                account: accountSettings,
                                                transferViewModelFactory: transferViewModelFactory,
                                                assetSelectionFactory: assetSelectionFactory,
                                                accessoryFactory: accessoryViewModelFactory,
                                                localizationManager: LocalizationManager(localization: WalletLanguage.english.rawValue))

            presenter.setup()

            wait(for: [titleExpectation,
                       assetExpectation,
                       amountExpectation,
                       feeExpectation,
                       descriptionExpectation,
                       balanceExpectation,
                       accessoryExpectation,
                       feeLoadedExpectation],
                 timeout: Constants.networkTimeout)

            // then

            XCTAssertNil(presenter.confirmationState)

            guard let currentAmountViewModel = amountViewModel else {
                XCTFail("Unexpected empty amount view model")
                return
            }

            guard let currentDescriptionViewModel = descriptionViewModel else {
                XCTFail("Unexpected empty description view model")
                return
            }

            _ = currentAmountViewModel.didReceiveReplacement(inputAmount,
                                                             for: NSRange(location: 0, length: 0))
            _ = currentDescriptionViewModel.didReceiveReplacement(inputDescription,
                                                                  for: NSRange(location: 0, length: 0))

            beforeConfirmationBlock?()

            presenter.confirm()

            XCTAssertEqual(presenter.confirmationState, .waiting)

            if expectsSuccess {
                wait(for: [confirmExpectation], timeout: Constants.networkTimeout)

                if let expectedAmount = expectedAmount {
                    XCTAssertEqual(expectedAmount, payloadToConfirm?.transferInfo.amount.decimalValue)
                }

                if let expectedFee = expectedFee {
                    XCTAssertEqual(expectedFee, payloadToConfirm?.transferInfo.fee?.decimalValue)
                }
            } else {
                wait(for: [errorExpectation], timeout: Constants.networkTimeout)
            }

            XCTAssertNil(presenter.confirmationState)

        } catch {
            XCTFail("\(error)")
        }
    }
}
