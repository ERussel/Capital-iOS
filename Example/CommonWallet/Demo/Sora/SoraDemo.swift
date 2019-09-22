/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation
import CommonWallet
import IrohaCommunication

final class SoraDemo: DemoFactoryProtocol {
    private var completionBlock: DemoCompletionBlock?

    var title: String {
        return "Sora"
    }

    func setupDemo(with completionBlock: @escaping DemoCompletionBlock) throws -> UIViewController {
        let account = try createAccountSettings()

        let networkResolver = DemoNetworkResolver()

        let transactionTypes = createTransactionTypes()

        let walletBuilder =  CommonWalletBuilder
            .builder(with: account, networkResolver: networkResolver)
            .with(amountFormatter: NumberFormatter.amount)
            .with(transferAmountLimit: 1e+12)
            .with(transactionTypeList: transactionTypes)
            .with(inputValidatorFactory: DemoInputValidatorFactory())
            .with(feeInfoFactory: SoraFeeInfoFactory())

        let accountListActions = createAccountListActions(for: walletBuilder.accountListModuleBuilder)
        let accountListViewModelFactory = SoraAccountListViewModelFactory(actionsViewModel: accountListActions)

        try setupAccountListModule(builder: walletBuilder.accountListModuleBuilder,
                                   viewModelFactory: accountListViewModelFactory)
        setupHistoryModule(builder: walletBuilder.historyModuleBuilder)
        setupContactsModule(builder: walletBuilder.contactsModuleBuilder)
        setupReceiveModule(builder: walletBuilder.receiveModuleBuilder, assets: account.assets)
        setupDepositModule(builder: walletBuilder.depositModuleBuilder)
        setupStyle(builder: walletBuilder.styleBuilder)

        let walletContext = try walletBuilder.build()

        setupAccountListCommand(for: accountListActions, context: walletContext)

        try mock(networkResolver: networkResolver, with: account.assets)

        self.completionBlock = completionBlock

        let rootController = try walletContext.createRootController()

        return rootController
    }

    private func setupAccountListModule(builder: AccountListModuleBuilderProtocol,
                                        viewModelFactory: AccountListViewModelFactoryProtocol) throws {
        let demoTitleStyle = WalletTextStyle(font: .demoHeader2, color: .black)
        let demoHeaderViewModel = DemoHeaderViewModel(title: "Wallet",
                                                      style: demoTitleStyle)
        demoHeaderViewModel.delegate = self

        let demoHeaderNib = UINib(nibName: "DemoHeaderCell", bundle: Bundle(for: type(of: self)))
        try builder
            .inserting(viewModelFactory: { demoHeaderViewModel }, at: 0)
            .with(cellNib: demoHeaderNib, for: demoHeaderViewModel.cellReuseIdentifier)
            .withActions(cellNib: UINib(nibName: "SoraActionsCollectionViewCell",
                                        bundle: Bundle(for: type(of: self))))
            .with(listViewModelFactory: viewModelFactory)
    }

    private func createAccountListActions(for builder: AccountListModuleBuilderProtocol)
        -> SoraActionsViewModel {
            let sendStyle = WalletTextStyle(font: .demoBodyBold,
                                            color: UIColor(red: 208.0 / 255.0,
                                                           green: 2.0 / 255.0,
                                                           blue: 27.0 / 255.0,
                                                           alpha: 1.0))

            let sendAction = SoraActionViewModel(title: "Send",
                                                 style: sendStyle)

            let receiveStyle = WalletTextStyle(font: .demoBodyBold,
                                               color: UIColor(red: 0.0 / 255.0,
                                                              green: 161.0 / 255.0,
                                                              blue: 103.0 / 255.0,
                                                              alpha: 1.0))

            let receiveAction = SoraActionViewModel(title: "Receive",
                                                    style: receiveStyle)

            let depositStyle = WalletTextStyle(font: .demoBodyBold,
                                               color: UIColor(red: 86.0 / 255.0,
                                                              green: 160.0 / 255.0,
                                                              blue: 190.0 / 255.0,
                                                              alpha: 1.0))

            let depositAction = SoraActionViewModel(title: "Deposit",
                                                    style: depositStyle)

            return SoraActionsViewModel(cellReuseIdentifier: builder.actionsCellIdentifier,
                                        itemHeight: 65.0,
                                        sendViewModel: sendAction,
                                        receiveViewModel: receiveAction,
                                        depositViewModel: depositAction)
    }

    private func setupAccountListCommand(for actions: SoraActionsViewModel,
                                         context: CommonWalletContextProtocol) {
        if let sendViewModel = actions.send as? SoraActionViewModel {
            sendViewModel.underlyingCommand = context.prepareSendCommand(for: nil)
        }

        if let receiveViewModel = actions.receive as? SoraActionViewModel {
            receiveViewModel.underlyingCommand = context.prepareReceiveCommand(for: nil)
        }

        if let depositViewModel = actions.deposit as? SoraActionViewModel {
            depositViewModel.underlyingCommand = context.prepareDepositCommand()
        }
    }

    private func setupHistoryModule(builder: HistoryModuleBuilderProtocol) {
        builder
            .with(emptyStateDataSource: DefaultEmptyStateDataSource.history)
            .with(supportsFilter: false)
    }

    private func setupContactsModule(builder: ContactsModuleBuilderProtocol) {
        builder
            .with(searchPlaceholder: "Phone number or account id")
            .with(contactsEmptyStateDataSource: DefaultEmptyStateDataSource.contacts)
            .with(searchEmptyStateDataSource: DefaultEmptyStateDataSource.search)
            .with(supportsLiveSearch: true)
    }

    private func setupReceiveModule(builder: ReceiveAmountModuleBuilderProtocol, assets: [WalletAsset]) {
        let accountShareFactory = SoraAccountShareFactory(assets: assets,
                                                          amountFormatter: NumberFormatter.amount)
        builder.with(accountShareFactory: accountShareFactory)
    }

    private func setupDepositModule(builder: DepositModuleBuilderProtocol) {
        let ethereumAddress = "0xde00295669a9FD93d5F2819Ec85E40f4cb69702e"
        let viewModelFactory = SoraDepositViewModelFactory(ethereumAddress: ethereumAddress)

        builder.with(viewModelFactory: viewModelFactory)
    }

    private func createAccountSettings() throws -> WalletAccountSettingsProtocol {
        let accountId = try IRAccountIdFactory.account(withIdentifier: String.accountId)
        let assets = try createAssets()

        guard let keypair = IREd25519KeyFactory().createRandomKeypair() else {
            throw DemoFactoryError.keypairGenerationFailed
        }

        guard let signer = IREd25519Sha512Signer(privateKey: keypair.privateKey()) else {
            throw DemoFactoryError.signerCreationFailed
        }

        var account = WalletAccountSettings(accountId: accountId,
                                            assets: assets,
                                            signer: signer,
                                            publicKey: keypair.publicKey())
        account.withdrawOptions = createWithdrawOptions()

        return account
    }

    private func setupStyle(builder: WalletStyleBuilderProtocol) {
        let caretColor = UIColor(red: 208.0 / 255.0, green: 2.0 / 255.0, blue: 27.0 / 255.0, alpha: 1.0)
        builder.with(caretColor: caretColor)

        builder
            .with(header1: .demoHeader1)
            .with(header2: .demoHeader2)
            .with(header3: .demoHeader3)
            .with(header4: .demoHeader4)
            .with(bodyRegular: .demoBodyRegular)
            .with(small: .demoSmall)
    }

    private func createTransactionTypes() -> [WalletTransactionType] {
        let incomingType = WalletTransactionType(backendName: "INCOMING",
                                                 displayName: "",
                                                 isIncome: true,
                                                 typeIcon: nil)

        let outgoingType = WalletTransactionType(backendName: "OUTGOING",
                                                 displayName: "",
                                                 isIncome: false,
                                                 typeIcon: nil)

        let withdrawType = WalletTransactionType(backendName: "WITHDRAW",
                                                 displayName: "Withdrawal",
                                                 isIncome: false,
                                                 typeIcon: nil)

        return [incomingType, outgoingType, withdrawType]
    }

    private func createAssets() throws -> [WalletAsset] {
        let soraAssetId = try IRAssetIdFactory.asset(withIdentifier: String.xorAssetId)
        let soraAsset = WalletAsset(identifier: soraAssetId,
                                    symbol: String(Character("\u{E000}")),
                                    details: "XOR")

        let ethId = try IRAssetIdFactory.asset(withIdentifier: String.ethAssetId)
        let ethAsset = WalletAsset(identifier: ethId,
                                   symbol: "Ξ",
                                   details: "ETHER")

        return [soraAsset, ethAsset]
    }

    private func createWithdrawOptions() -> [WalletWithdrawOption] {
        let icon = UIImage(named: "iconEth")

        let ethShortTitle = "Withdraw to Ethereum"
        let ethLongTitle = "Send to my Ethereum wallet"
        let ethDetails = "Ethereum wallet address"

        let ethWithdrawOption = WalletWithdrawOption(identifier: UUID().uuidString,
                                                     symbol: "ETH",
                                                     shortTitle: ethShortTitle,
                                                     longTitle: ethLongTitle,
                                                     details: ethDetails,
                                                     icon: icon)

        return [ethWithdrawOption]
    }
}

extension SoraDemo: DemoHeaderViewModelDelegate {
    func didSelectClose(for viewModel: DemoHeaderViewModelProtocol) {
        completionBlock?()
    }
}
