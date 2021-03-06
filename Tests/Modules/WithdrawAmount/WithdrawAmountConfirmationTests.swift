/**
 * Copyright Soramitsu Co., Ltd. All Rights Reserved.
 * SPDX-License-Identifier: GPL-3.0
 */

import XCTest
@testable import CommonWallet
import IrohaCommunication
import Cuckoo
import SoraFoundation

class WithdrawAmountConfirmationTests: NetworkBaseTests {

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

    func testFeeNotAvailable() {
        let networkResolver = MockNetworkResolver()
        performConfirmationTest(for: networkResolver,
                                transactionSettingsFactory: WalletTransactionSettingsFactory(),
                                inputAmount: "100",
                                inputDescription: "",
                                expectsSuccess: false) {
            try? WithdrawalMetadataMock.register(mock: .notAvailable,
                                                networkResolver: networkResolver,
                                                requestType: .withdrawalMetadata,
                                                httpMethod: .get,
                                                urlMockType: .regex)
        }
    }

    func testMinimumAmountInput() {
        let networkResolver = MockNetworkResolver()

        let settingsMock = MockWalletTransactionSettingsFactoryProtocol()

        stub(settingsMock) { stub in
            when(stub).createSettings(for: any(), senderId: any(), receiverId: any()).then { _ in
                WalletTransactionSettings(transferLimit: WalletTransactionLimit(minimum: 0, maximum: 1e+6),
                                          withdrawLimit: WalletTransactionLimit(minimum: 10, maximum: 1e+6))
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
                                expectedFee: Decimal(string: "9")!)
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
                                expectedAmount: Decimal(string: "79.2")!,
                                expectedFee: Decimal(string: "0.8")!)
    }

    // MARK: Private

    private func performConfirmationTest(for networkResolver: WalletNetworkResolverProtocol,
                                         transactionSettingsFactory: WalletTransactionSettingsFactoryProtocol,
                                         inputAmount: String,
                                         inputDescription: String,
                                         expectsSuccess: Bool,
                                         metadataMock: WithdrawalMetadataMock = .success,
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
            let withdrawOption = createRandomWithdrawOption()

            let accountSettings = try createRandomAccountSettings(for: [walletAsset],
                                                                  withdrawOptions: [withdrawOption])

            let selectedAsset = accountSettings.assets.first!
            let selectionOption = accountSettings.withdrawOptions.first!

            let cacheFacade = CoreDataTestCacheFacade()

            let networkOperationFactory = MiddlewareOperationFactory(accountSettings: accountSettings,
                                                                     networkResolver: networkResolver)

            let dataProviderFactory = DataProviderFactory(accountSettings: accountSettings,
                                                          cacheFacade: cacheFacade,
                                                          networkOperationFactory: networkOperationFactory)

            let inputValidatorFactory = WalletInputValidatorFactoryDecorator(descriptionMaxLength: 64)
            let viewModelFactory = WithdrawAmountViewModelFactory(amountFormatterFactory: NumberFormatterFactory(),
                                                                  option: selectionOption,
                                                                  descriptionValidatorFactory: inputValidatorFactory,
                                                                  transactionSettingsFactory: transactionSettingsFactory,
                                                                  feeDisplaySettingsFactory: FeeDisplaySettingsFactory())

            let view = MockAmountViewProtocol()
            let coordinator = MockWithdrawAmountCoordinatorProtocol()

            let assetViewModelObserver = MockAssetSelectionViewModelObserver()
            let feeViewModelObserver = MockFeeViewModelObserver()

            // when

            try FetchBalanceMock.register(mock: .success,
                                          networkResolver: networkResolver,
                                          requestType: .balance,
                                          httpMethod: .post)

            try WithdrawalMetadataMock.register(mock: metadataMock,
                                                networkResolver: networkResolver,
                                                requestType: .withdrawalMetadata,
                                                httpMethod: .get,
                                                urlMockType: .regex)

            let titleExpectation = XCTestExpectation()
            let assetSelectionExpectation = XCTestExpectation()
            let amountExpectation = XCTestExpectation()
            let feeExpectation = XCTestExpectation()
            let descriptionExpectation = XCTestExpectation()
            let accessoryExpectation = XCTestExpectation()
            let errorExpectation = XCTestExpectation()
            let balanceLoadedExpectation = XCTestExpectation()
            
            let feeLoadedExpectation = XCTestExpectation()
            feeLoadedExpectation.expectedFulfillmentCount = 2

            var amountViewModel: AmountInputViewModelProtocol?
            var descriptionViewModel: DescriptionInputViewModelProtocol?

            stub(view) { stub in
                when(stub).set(title: any(String.self)).then { _ in
                    titleExpectation.fulfill()
                }

                when(stub).set(assetViewModel: any()).then { viewModel in
                    viewModel.observable.add(observer: assetViewModelObserver)

                    assetSelectionExpectation.fulfill()
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

                when(stub).isSetup.get.thenReturn(false, true)

                when(stub).didStartLoading().thenDoNothing()
                when(stub).didStopLoading().thenDoNothing()
            }

            stub(assetViewModelObserver) { stub in
                when(stub).assetSelectionDidChangeTitle().then {
                    balanceLoadedExpectation.fulfill()
                }
            }

            stub(feeViewModelObserver) { stub in
                when(stub).feeTitleDidChange().thenDoNothing()

                when(stub).feeLoadingStateDidChange().then {
                    feeLoadedExpectation.fulfill()
                }
            }

            let confirmExpectation = XCTestExpectation()

            var infoToConfirm: WithdrawInfo?

            stub(coordinator) { stub in
                when(stub).confirm(with: any(WithdrawInfo.self),
                                   asset: any(WalletAsset.self),
                                   option: any(WalletWithdrawOption.self)).then { info, asset, option in
                                    infoToConfirm = info
                                    confirmExpectation.fulfill()
                }
            }

            let assetSelectionFactory = AssetSelectionFactory(amountFormatterFactory: NumberFormatterFactory())

            let presenter = try WithdrawAmountPresenter(view: view,
                                                        coordinator: coordinator,
                                                        assets: accountSettings.assets,
                                                        selectedAsset: selectedAsset,
                                                        selectedOption: selectionOption,
                                                        dataProviderFactory: dataProviderFactory,
                                                        feeCalculationFactory: FeeCalculationFactory(),
                                                        withdrawViewModelFactory: viewModelFactory,
                                                        assetTitleFactory: assetSelectionFactory,
                                                        localizationManager: LocalizationManager(localization: WalletLanguage.english.rawValue))

            // then

            presenter.setup()

            wait(for: [titleExpectation,
                       assetSelectionExpectation,
                       amountExpectation,
                       feeExpectation,
                       descriptionExpectation,
                       accessoryExpectation,
                       balanceLoadedExpectation,
                       feeLoadedExpectation], timeout: Constants.networkTimeout)

            XCTAssertNil(presenter.confirmationState)

            _ = amountViewModel?.didReceiveReplacement(inputAmount, for: NSRange(location: 0, length: 0))
            _ = descriptionViewModel?.didReceiveReplacement(description, for: NSRange(location: 0, length: 0))

            beforeConfirmationBlock?()

            presenter.confirm()

            XCTAssertEqual(presenter.confirmationState, .waiting)

            if expectsSuccess {
                wait(for: [confirmExpectation], timeout: Constants.networkTimeout)
                
                if let expectedAmount = expectedAmount {
                    XCTAssertEqual(expectedAmount, infoToConfirm?.amount.decimalValue)
                }

                if let expectedFee = expectedFee {
                    XCTAssertEqual(expectedFee, infoToConfirm?.fee?.decimalValue)
                }

            } else {
                wait(for: [errorExpectation], timeout: Constants.networkTimeout)
            }

            XCTAssertNil(presenter.confirmationState)

        } catch {
            XCTFail("Did receive error \(error)")
        }
    }
}
