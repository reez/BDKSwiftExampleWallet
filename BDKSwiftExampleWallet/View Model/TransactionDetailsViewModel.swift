//
//  TransactionDetailsViewModel.swift
//  BDKSwiftExampleWallet
//
//  Created by Matthew Ramsden on 2/15/24.
//

import BitcoinDevKit
import Foundation

class TransactionDetailsViewModel: ObservableObject {
    let bdkClient: BDKClient
    let keyClient: KeyClient

    @Published var network: String?
    @Published var esploraURL: String?

    @Published var esploraError: EsploraError?
    @Published var calculateFeeError: CalculateFeeError?
    @Published var transactionDetailsError: AppError?

    @Published var showingTransactionDetailsViewErrorAlert = false
    @Published var calculateFee: String?

    init(
        bdkClient: BDKClient = .live,
        keyClient: KeyClient = .live
    ) {
        self.bdkClient = bdkClient
        self.keyClient = keyClient
    }

    func getNetwork() {
        do {
            self.network = try keyClient.getNetwork()
        } catch {
            DispatchQueue.main.async {
                self.transactionDetailsError = .generic(message: error.localizedDescription)
            }
        }
    }

    func getEsploraUrl() {
        do {
            let savedEsploraURL = try keyClient.getEsploraURL()
            if network == "Signet" {
                self.esploraURL = "https://mempool.space/signet"
            } else {
                self.esploraURL = savedEsploraURL
            }
        } catch let error as EsploraError {
            DispatchQueue.main.async {
                self.esploraError = error
            }
        } catch {}
    }

    func getSentAndReceived(tx: BitcoinDevKit.Transaction) -> SentAndReceivedValues? {
        do {
            let sentAndReceived = try bdkClient.sentAndReceived(tx)
            return sentAndReceived
        } catch {
            DispatchQueue.main.async {
                self.transactionDetailsError = .generic(message: error.localizedDescription)
            }
            return nil
        }
    }

    func getCalulateFee(tx: BitcoinDevKit.Transaction) {
        do {
            let calculateFee = try bdkClient.calculateFee(tx)
            let feeString = String(calculateFee)
            self.calculateFee = feeString
        } catch let error as CalculateFeeError {
            DispatchQueue.main.async {
                self.calculateFeeError = error
            }
        } catch {}
    }

}
