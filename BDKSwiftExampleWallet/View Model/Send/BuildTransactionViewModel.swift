//
//  BuildTransactionViewModel.swift
//  BDKSwiftExampleWallet
//
//  Created by Matthew Ramsden on 9/23/23.
//

import BitcoinDevKit
import Foundation

@MainActor
@Observable
class BuildTransactionViewModel {
    let bdkClient: BDKClient

    var buildTransactionViewError: AppError?
    var calculateFee: String?
    var psbt: Psbt?
    var showingBuildTransactionViewErrorAlert = false

    init(
        bdkClient: BDKClient = .live
    ) {
        self.bdkClient = bdkClient
    }

    func buildTransaction(address: String, amount: UInt64, feeRate: UInt64) {
        do {
            let txBuilderResult = try bdkClient.buildTransaction(address, amount, feeRate)
            self.psbt = txBuilderResult
        } catch let error as WalletError {
            self.buildTransactionViewError = .generic(message: error.localizedDescription)
            self.showingBuildTransactionViewErrorAlert = true
        } catch let error as AddressParseError {
            self.buildTransactionViewError = .generic(message: error.localizedDescription)
            self.showingBuildTransactionViewErrorAlert = true
        } catch {
            self.buildTransactionViewError = .generic(message: error.localizedDescription)
            self.showingBuildTransactionViewErrorAlert = true
        }
    }

    func extractTransaction() -> BitcoinDevKit.Transaction? {
        guard let psbt = self.psbt else {
            return nil
        }
        do {
            let transaction = try psbt.extractTx()
            return transaction
        } catch let error {
            self.buildTransactionViewError = .generic(
                message: "Failed to extract transaction: \(error.localizedDescription)"
            )
            self.showingBuildTransactionViewErrorAlert = true
            return nil
        }
    }

    func getCalulateFee(tx: BitcoinDevKit.Transaction) {
        do {
            let calculateFee = try bdkClient.calculateFee(tx)
            let feeString = String(calculateFee.toSat())
            self.calculateFee = feeString
        } catch let error as CalculateFeeError {
            self.buildTransactionViewError = .generic(message: error.localizedDescription)
        } catch {
            self.buildTransactionViewError = .generic(message: error.localizedDescription)
        }
    }

    func send(address: String, amount: UInt64, feeRate: UInt64) {
        do {
            try bdkClient.send(address, amount, feeRate)
            NotificationCenter.default.post(
                name: Notification.Name("TransactionSent"),
                object: nil
            )
        } catch let error as EsploraError {
            self.buildTransactionViewError = .generic(message: error.localizedDescription)
            self.showingBuildTransactionViewErrorAlert = true
        } catch let error as SignerError {
            self.buildTransactionViewError = .generic(message: error.localizedDescription)
            self.showingBuildTransactionViewErrorAlert = true
        } catch let error as WalletError {
            self.buildTransactionViewError = .generic(message: error.localizedDescription)
            self.showingBuildTransactionViewErrorAlert = true
        } catch {
            self.buildTransactionViewError = .generic(message: error.localizedDescription)
            self.showingBuildTransactionViewErrorAlert = true
        }
    }

}
