/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation
import RobinHood

typealias WalletQRServiceCompletionBlock = (Result<UIImage, Error>?) -> Void

protocol WalletQRServiceProtocol: class {
    @discardableResult
    func generate<I: Codable>(from info: I,
                              qrSize: CGSize,
                              runIn queue: DispatchQueue,
                              completionBlock: @escaping WalletQRServiceCompletionBlock) throws -> Operation

    @discardableResult
    func generate(using data: Data,
                  qrSize: CGSize,
                  runIn queue: DispatchQueue,
                  completionBlock: @escaping WalletQRServiceCompletionBlock) -> Operation
}

final class WalletQRService {
    let operationFactory: WalletQROperationFactoryProtocol
    let operationQueue: OperationQueue

    private let encoder: WalletQREncoderProtocol

    init(operationFactory: WalletQROperationFactoryProtocol,
         encoder: WalletQREncoderProtocol = WalletQREncoder(),
         operationQueue: OperationQueue = OperationQueue()) {
        self.operationFactory = operationFactory
        self.encoder = encoder
        self.operationQueue = operationQueue
    }
}

extension WalletQRService: WalletQRServiceProtocol {
    @discardableResult
    func generate<I: Codable>(from info: I,
                              qrSize: CGSize,
                              runIn queue: DispatchQueue,
                              completionBlock: @escaping WalletQRServiceCompletionBlock) throws -> Operation {
        let payload = try encoder.encode(info)
        return generate(using: payload,
                        qrSize: qrSize,
                        runIn: queue,
                        completionBlock: completionBlock)
    }

    @discardableResult
    func generate(using data: Data,
                  qrSize: CGSize,
                  runIn queue: DispatchQueue,
                  completionBlock: @escaping WalletQRServiceCompletionBlock) throws -> Operation {

        let operation = operationFactory.createCreationOperation(for: data, qrSize: qrSize)

        operation.completionBlock = {
            queue.async {
                completionBlock(operation.result)
            }
        }

        operationQueue.addOperation(operation)
        return operation
    }
}
