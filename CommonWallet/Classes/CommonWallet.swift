/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import UIKit

public protocol CommonWalletBuilderProtocol: class {
    static func builder(with account: WalletAccountSettingsProtocol,
                        networkResolver: WalletNetworkResolverProtocol) -> CommonWalletBuilderProtocol

    static func builder(with account: WalletAccountSettingsProtocol,
                        networkOperationFactory: WalletNetworkOperationFactoryProtocol)
        -> CommonWalletBuilderProtocol

    var accountListModuleBuilder: AccountListModuleBuilderProtocol { get }
    var historyModuleBuilder: HistoryModuleBuilderProtocol { get }
    var invoiceScanModuleBuilder: InvoiceScanModuleBuilderProtocol { get }
    var contactsModuleBuilder: ContactsModuleBuilderProtocol { get }
    var receiveModuleBuilder: ReceiveAmountModuleBuilderProtocol { get }
    var transactionDetailsModuleBuilder: TransactionDetailsModuleBuilderProtocol { get }
    var depositModuleBuilder: DepositModuleBuilderProtocol { get }
    var styleBuilder: WalletStyleBuilderProtocol { get }

    @discardableResult
    func with(networkOperationFactory: WalletNetworkOperationFactoryProtocol) -> Self

    @discardableResult
    func with(feeCalculationFactory: FeeCalculationFactoryProtocol) -> Self

    @discardableResult
    func with(feeInfoFactory: FeeInfoFactoryProtocol) -> Self

    @discardableResult
    func with(amountFormatter: NumberFormatter) -> Self

    @discardableResult
    func with(statusDateFormatter: DateFormatter) -> Self

    @discardableResult
    func with(transferDescriptionLimit: UInt8) -> Self

    @discardableResult
    func with(transferAmountLimit: Decimal) -> Self

    @discardableResult
    func with(logger: WalletLoggerProtocol) -> Self
    
    @discardableResult
    func with(transactionTypeList: [WalletTransactionType]) -> Self

    @discardableResult
    func with(commandDecoratorFactory: WalletCommandDecoratorFactoryProtocol) -> Self

    @discardableResult
    func with(inputValidatorFactory: WalletInputValidatorFactoryProtocol) -> Self

    @discardableResult
    func with(qrCoderFactory: WalletQRCoderFactoryProtocol) -> Self

    func build() throws -> CommonWalletContextProtocol
}

public enum CommonWalletBuilderError: Error {
    case moduleCreationFailed
}

public final class CommonWalletBuilder {
    fileprivate var privateAccountModuleBuilder: AccountListModuleBuilder
    fileprivate var privateHistoryModuleBuilder: HistoryModuleBuilder
    fileprivate var privateContactsModuleBuilder: ContactsModuleBuilder
    fileprivate var privateInvoiceScanModuleBuilder: InvoiceScanModuleBuilder
    fileprivate var privateReceiveModuleBuilder: ReceiveAmountModuleBuilder
    fileprivate var privateTransactionDetailsModuleBuilder: TransactionDetailsModuleBuilder
    fileprivate var privateDepositModuleBuilder: DepositModuleBuilder?
    fileprivate var privateStyleBuilder: WalletStyleBuilder
    fileprivate var account: WalletAccountSettingsProtocol
    fileprivate var networkOperationFactory: WalletNetworkOperationFactoryProtocol
    fileprivate lazy var feeCalculationFactory: FeeCalculationFactoryProtocol = FeeCalculationFactory()
    fileprivate var feeInfoFactory: FeeInfoFactoryProtocol?
    fileprivate var logger: WalletLoggerProtocol?
    fileprivate var amountFormatter: NumberFormatter?
    fileprivate var statusDateFormatter: DateFormatter?
    fileprivate var transferDescriptionLimit: UInt8 = 64
    fileprivate var transferAmountLimit: Decimal?
    fileprivate var transactionTypeList: [WalletTransactionType]?
    fileprivate var commandDecoratorFactory: WalletCommandDecoratorFactoryProtocol?
    fileprivate var inputValidatorFactory: WalletInputValidatorFactoryProtocol?
    fileprivate var qrCoderFactory: WalletQRCoderFactoryProtocol?

    init(account: WalletAccountSettingsProtocol, networkOperationFactory: WalletNetworkOperationFactoryProtocol) {
        self.account = account
        self.networkOperationFactory = networkOperationFactory
        privateAccountModuleBuilder = AccountListModuleBuilder()
        privateHistoryModuleBuilder = HistoryModuleBuilder()
        privateContactsModuleBuilder = ContactsModuleBuilder()
        privateInvoiceScanModuleBuilder = InvoiceScanModuleBuilder()
        privateReceiveModuleBuilder = ReceiveAmountModuleBuilder()
        privateTransactionDetailsModuleBuilder = TransactionDetailsModuleBuilder()
        privateStyleBuilder = WalletStyleBuilder()
    }
}

extension CommonWalletBuilder: CommonWalletBuilderProtocol {
    public var accountListModuleBuilder: AccountListModuleBuilderProtocol {
        return privateAccountModuleBuilder
    }

    public var historyModuleBuilder: HistoryModuleBuilderProtocol {
        return privateHistoryModuleBuilder
    }
    
    public var contactsModuleBuilder: ContactsModuleBuilderProtocol {
        return privateContactsModuleBuilder
    }

    public var invoiceScanModuleBuilder: InvoiceScanModuleBuilderProtocol {
        return privateInvoiceScanModuleBuilder
    }

    public var receiveModuleBuilder: ReceiveAmountModuleBuilderProtocol {
        return privateReceiveModuleBuilder
    }

    public var transactionDetailsModuleBuilder: TransactionDetailsModuleBuilderProtocol {
        return privateTransactionDetailsModuleBuilder
    }

    public var depositModuleBuilder: DepositModuleBuilderProtocol {
        if let depositModuleBuilder = privateDepositModuleBuilder {
            return depositModuleBuilder
        }

        let newModuleBuilder = DepositModuleBuilder()
        privateDepositModuleBuilder = newModuleBuilder

        return newModuleBuilder
    }

    public var styleBuilder: WalletStyleBuilderProtocol {
        return privateStyleBuilder
    }

    public static func builder(with account: WalletAccountSettingsProtocol,
                               networkResolver: WalletNetworkResolverProtocol) -> CommonWalletBuilderProtocol {
        let networkOperationFactory = MiddlewareOperationFactory(accountSettings: account,
                                                                 networkResolver: networkResolver)
        return CommonWalletBuilder(account: account, networkOperationFactory: networkOperationFactory)
    }

    public static func builder(with account: WalletAccountSettingsProtocol,
                               networkOperationFactory: WalletNetworkOperationFactoryProtocol)
        -> CommonWalletBuilderProtocol {
        return CommonWalletBuilder(account: account, networkOperationFactory: networkOperationFactory)
    }

    public func with(networkOperationFactory: WalletNetworkOperationFactoryProtocol) -> Self {
        self.networkOperationFactory = networkOperationFactory

        return self
    }

    public func with(feeCalculationFactory: FeeCalculationFactoryProtocol) -> Self {
        self.feeCalculationFactory = feeCalculationFactory

        return self
    }

    public func with(feeInfoFactory: FeeInfoFactoryProtocol) -> Self {
        self.feeInfoFactory = feeInfoFactory

        return self
    }

    public func with(amountFormatter: NumberFormatter) -> Self {
        self.amountFormatter = amountFormatter

        return self
    }

    public func with(statusDateFormatter: DateFormatter) -> Self {
        self.statusDateFormatter = statusDateFormatter

        return self
    }

    public func with(logger: WalletLoggerProtocol) -> Self {
        self.logger = logger
        return self
    }

    public func with(transferDescriptionLimit: UInt8) -> Self {
        self.transferDescriptionLimit = transferDescriptionLimit
        return self
    }

    public func with(transferAmountLimit: Decimal) -> Self {
        self.transferAmountLimit = transferAmountLimit
        return self
    }
    
    public func with(transactionTypeList: [WalletTransactionType]) -> Self {
        self.transactionTypeList = transactionTypeList
        return self
    }

    public func with(commandDecoratorFactory: WalletCommandDecoratorFactoryProtocol) -> Self {
        self.commandDecoratorFactory = commandDecoratorFactory
        return self
    }

    public func with(inputValidatorFactory: WalletInputValidatorFactoryProtocol) -> Self {
        self.inputValidatorFactory = inputValidatorFactory
        return self
    }

    public func with(qrCoderFactory: WalletQRCoderFactoryProtocol) -> Self {
        self.qrCoderFactory = qrCoderFactory
        return self
    }

    public func build() throws -> CommonWalletContextProtocol {
        let style = privateStyleBuilder.build()

        let resolver = try createResolver(with: style)

        resolver.depositConfiguration = try privateDepositModuleBuilder?.build()
        resolver.commandDecoratorFactory = commandDecoratorFactory

        resolver.style = style

        resolver.logger = logger

        if let amountFormatter = amountFormatter {
            resolver.amountFormatter = amountFormatter
        }

        if let statusDateFormatter = statusDateFormatter {
            resolver.statusDateFormatter = statusDateFormatter
        }

        if let transferAmountLimit = transferAmountLimit {
            resolver.transferAmountLimit = transferAmountLimit
        }

        if let transactionTypeList = transactionTypeList {
            resolver.transactionTypeList = transactionTypeList

            WalletTransactionType.required.forEach { type in
                if !resolver.transactionTypeList.contains(where: { $0.backendName == type.backendName }) {
                    resolver.transactionTypeList.insert(type, at: 0)
                }
            }

        } else {
            resolver.transactionTypeList = WalletTransactionType.required
        }

        if let qrCoderFactory = qrCoderFactory {
            resolver.qrCoderFactory = qrCoderFactory
        }

        if let feeInfoFactory = feeInfoFactory {
            resolver.feeInfoFactory = feeInfoFactory
        }

        return resolver
    }

    private func createResolver(with style: WalletStyleProtocol) throws -> Resolver {

        privateAccountModuleBuilder.walletStyle = style
        let accountListConfiguration = try privateAccountModuleBuilder.build()

        privateHistoryModuleBuilder.walletStyle = style
        let historyConfiguration = privateHistoryModuleBuilder.build()

        privateContactsModuleBuilder.walletStyle = style
        let contactsConfiguration = privateContactsModuleBuilder.build()

        privateInvoiceScanModuleBuilder.walletStyle = style
        let invoiceScanConfiguration = privateInvoiceScanModuleBuilder.build()

        let receiveConfiguration = privateReceiveModuleBuilder.build()

        let transactionDetailsConfiguration = privateTransactionDetailsModuleBuilder.build()

        let decorator = WalletInputValidatorFactoryDecorator(descriptionMaxLength: transferDescriptionLimit)
        decorator.underlyingFactory = inputValidatorFactory

        let resolver = Resolver(account: account,
                                networkOperationFactory: networkOperationFactory,
                                accountListConfiguration: accountListConfiguration,
                                historyConfiguration: historyConfiguration,
                                contactsConfiguration: contactsConfiguration,
                                invoiceScanConfiguration: invoiceScanConfiguration,
                                receiveConfiguration: receiveConfiguration,
                                transactionDetailsConfiguration: transactionDetailsConfiguration,
                                inputValidatorFactory: decorator,
                                feeCalculationFactory: feeCalculationFactory)

        return resolver
    }
}
