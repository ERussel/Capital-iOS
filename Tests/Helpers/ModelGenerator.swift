/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation
@testable import CommonWallet
import IrohaCommunication

enum BytesGeneratorError: Error {
    case bytesGenerationFailed
}

func createRandomData(with bytesCount: Int) throws -> Data {
    var data = Data(count: bytesCount)

    let result = data.withUnsafeMutableBytes { (mutableBytes: UnsafeMutableRawBufferPointer) -> Int32 in
        guard let address = mutableBytes.baseAddress else {
            return errSecParam
        }

        return SecRandomCopyBytes(kSecRandomDefault, bytesCount, address)
    }

    if result != errSecSuccess {
        throw BytesGeneratorError.bytesGenerationFailed
    }

    return data
}

func createRandomTransactionHash() throws -> Data {
    return try createRandomData(with: 32)
}

func createRandomTransferInfo(differentFeesCount: Int = 1) throws -> TransferInfo {
    let source = try IRAccountIdFactory.account(withIdentifier: try createRandomAccountId())
    let destination = try IRAccountIdFactory.account(withIdentifier: try createRandomAccountId())
    let amount = try IRAmountFactory.amount(fromUnsignedInteger: UInt.random(in: 1...1000))
    let asset = try IRAssetIdFactory.asset(withIdentifier: createRandomAssetId())
    let details = UUID().uuidString

    let fees = try (0..<differentFeesCount).map { _ in try createRandomFeeInfo() }

    return TransferInfo(source: source,
                        destination: destination,
                        amount: amount,
                        asset: asset,
                        details: details,
                        fees: fees)
}

func createRandomWithdrawInfo(differentFeesCount: Int = 1) throws -> WithdrawInfo {
    let destinationAccount = try IRAccountIdFactory.account(withIdentifier: try createRandomAccountId())
    let amount = try IRAmountFactory.amount(fromUnsignedInteger: UInt.random(in: 1...1000))
    let asset = try IRAssetIdFactory.asset(withIdentifier: createRandomAssetId())
    let details = UUID().uuidString

    let fees = try (0..<differentFeesCount).map { _ in try createRandomFeeInfo() }

    return WithdrawInfo(destinationAccountId: destinationAccount,
                        assetId: asset,
                        amount: amount,
                        details: details,
                        fees: fees)
}

func createRandomReceiveInfo() throws -> ReceiveInfo {
    let accountId = try IRAccountIdFactory.account(withIdentifier: try createRandomAccountId())
    let amount = try IRAmountFactory.amount(fromUnsignedInteger: UInt.random(in: 1...1000))
    let assetId = try IRAssetIdFactory.asset(withIdentifier: createRandomAssetId())
    let details = UUID().uuidString

    return ReceiveInfo(accountId: accountId,
                       assetId: assetId,
                       amount: amount,
                       details: details)
}

func createRandomAssetTransactionData(differentFeesCount: Int = 1) throws -> AssetTransactionData {
    let transactionId = try createRandomTransactionHash()
    let status: AssetTransactionStatus = [.commited, .pending, .rejected].randomElement()!
    let assetId = try createRandomAssetId()
    let amount = UInt.random(in: 0...1000)
    let reason: String? = status == .rejected ? UUID().uuidString : nil

    let fees = try (0..<differentFeesCount).map { _ in try createRandomAssetAmountData() }

    return AssetTransactionData(transactionId: (transactionId as NSData).toHexString(),
                                status: status,
                                assetId: assetId,
                                peerId: UUID().uuidString,
                                peerName: UUID().uuidString,
                                details: UUID().uuidString,
                                amount: NSNumber(value: amount).stringValue,
                                fees: fees,
                                timestamp: Int64(Date().timeIntervalSince1970),
                                type: WalletTransactionType.required.randomElement()!.backendName,
                                reason: reason)
}

func createRandomTransactionType() -> WalletTransactionType {
    return WalletTransactionType(backendName: UUID().uuidString,
                                 displayName: UUID().uuidString,
                                 isIncome: [false, true].randomElement()!,
                                 typeIcon: nil)
}

func createRandomWithdrawMetadataInfo() throws -> WithdrawMetadataInfo {
    let assetId = try createRandomAssetId()
    let option = UUID().uuidString

    return WithdrawMetadataInfo(assetId: assetId, option: option)
}

func createRandomFeeInfo() throws -> FeeInfo {
    let assetId = try IRAssetIdFactory.asset(withIdentifier: createRandomAssetId())
    let accountId = try IRAccountIdFactory.account(withIdentifier: createRandomAccountId())
    let amount = try IRAmountFactory.amount(fromUnsignedInteger: UInt.random(in: 1...1000))

    return FeeInfo(assetId: assetId, amount: amount, accountId: accountId)
}

func createRandomAssetAmountData() throws -> AssetAmountData {
    let assetId = try createRandomAssetId()
    let amount = NSNumber(value: UInt.random(in: 1...1000)).stringValue
    return AssetAmountData(assetId: assetId, amount: amount)
}
