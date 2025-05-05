//
//  OnboardingViewModel.swift
//  BDKSwiftExampleWallet
//
//  Created by Matthew Ramsden on 8/6/23.
//

import BitcoinDevKit
import CKTap
import CoreNFC
import Foundation
import SwiftUI

// Can't make @Observable yet
// https://developer.apple.com/forums/thread/731187
// Feature or Bug?
class OnboardingViewModel: NSObject, ObservableObject, NFCTagReaderSessionDelegate {
    let bdkClient: BDKClient

    @AppStorage("isOnboarding") var isOnboarding: Bool?

    @Published var tagSession: NFCTagReaderSession?
    @Published var lastStatusMessage: String = "Tap button to scan card"
    @Published var isScanning: Bool = false
    @Published var didCompleteSuccessfully: Bool = false
    @Published var showNFCSucceessSheet: Bool = false
    @Published var lastStatusResponse: FfiStatusResponse?

    @Published var createWithPersistError: CreateWithPersistError?
    var isDescriptor: Bool {
        words.hasPrefix("tr(") || words.hasPrefix("wpkh(") || words.hasPrefix("wsh(")
            || words.hasPrefix("sh(")
    }
    var isXPub: Bool {
        words.hasPrefix("xpub") || words.hasPrefix("tpub") || words.hasPrefix("vpub")
    }
    @Published var networkColor = Color.gray
    @Published var onboardingViewError: AppError?
    @Published var selectedNetwork: Network = .signet {
        didSet {
            bdkClient.updateNetwork(selectedNetwork)
            selectedURL = availableURLs.first ?? ""
            bdkClient.updateEsploraURL(selectedURL)
        }
    }
    @Published var selectedURL: String = "" {
        didSet {
            bdkClient.updateEsploraURL(selectedURL)
        }
    }
    @Published var words: String = ""
    var wordArray: [String] {
        if words.hasPrefix("xpub") || words.hasPrefix("tpub") || words.hasPrefix("vpub") {
            return []
        }
        let trimmedWords = words.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedWords.components(separatedBy: " ")
    }
    var availableURLs: [String] {
        switch selectedNetwork {
        case .bitcoin:
            return Constants.Config.EsploraServerURLNetwork.Bitcoin.allValues
        case .testnet:
            return Constants.Config.EsploraServerURLNetwork.Testnet.allValues
        case .regtest:
            return Constants.Config.EsploraServerURLNetwork.Regtest.allValues
        case .signet:
            return Constants.Config.EsploraServerURLNetwork.Signet.allValues
        case .testnet4:
            return Constants.Config.EsploraServerURLNetwork.Testnet4.allValues
        }
    }
    var buttonColor: Color {
        switch selectedNetwork {
        case .bitcoin:
            return Constants.BitcoinNetworkColor.bitcoin.color
        case .testnet:
            return Constants.BitcoinNetworkColor.testnet.color
        case .signet:
            return Constants.BitcoinNetworkColor.signet.color
        case .regtest:
            return Constants.BitcoinNetworkColor.regtest.color
        case .testnet4:
            return Constants.BitcoinNetworkColor.testnet4.color
        }
    }

    init(
        bdkClient: BDKClient = .live
    ) {
        self.bdkClient = bdkClient
        self.selectedNetwork = bdkClient.getNetwork()
        self.selectedURL = bdkClient.getEsploraURL()
    }

    func createWallet() {
        do {
            try bdkClient.deleteWallet()
            if isDescriptor {
                try bdkClient.createWalletFromDescriptor(words)
            } else if isXPub {
                try bdkClient.createWalletFromXPub(words)
            } else {
                try bdkClient.createWalletFromSeed(words)
            }
            DispatchQueue.main.async {
                self.isOnboarding = false
            }
        } catch let error as CreateWithPersistError {
            DispatchQueue.main.async {
                self.createWithPersistError = error
            }
        } catch {
            DispatchQueue.main.async {
                self.onboardingViewError = .generic(message: error.localizedDescription)
            }
        }
    }
}

extension OnboardingViewModel {
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        print("NFC Session Active")
        DispatchQueue.main.async {
            self.lastStatusMessage = "Scanning for Card..."
            self.isScanning = true
        }
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Swift.Error)
    {
        print("NFC Session Invalidated: \(error.localizedDescription)")
        Task { @MainActor in
            // If we completed successfully, don't overwrite the success message.
            // Just reset the flag and ensure scanning is marked false.
            if self.didCompleteSuccessfully {
                self.isScanning = false
                self.didCompleteSuccessfully = false  // Reset for next scan
                print("NFC Session invalidated after successful operation.")
                return  // Don't proceed to overwrite message
            }

            if let nfcError = error as? NFCReaderError,
                nfcError.code == .readerSessionInvalidationErrorUserCanceled
            {
                self.lastStatusMessage = "Scan cancelled."
            } else if let nfcError = error as? NFCReaderError,
                nfcError.code == .readerSessionInvalidationErrorSessionTerminatedUnexpectedly
            {
                // This often happens after explicit invalidate(). We might not want to show an error.
                // If we didn't complete successfully, maybe revert to initial state?
                // Or keep the last relevant message?
                self.lastStatusMessage = "Session terminated."
                print("NFC Session terminated normally (potentially after manual invalidate).")
            } else {
                // Handle other errors
                self.lastStatusMessage = "NFC Error: \(error.localizedDescription)"
            }
            self.isScanning = false
        }
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        print("NFC Tag Detected")
        guard let firstTag = tags.first else {
            session.invalidate(errorMessage: "Could not detect tag.")
            return
        }

        Task { @MainActor in self.lastStatusMessage = "Card detected, connecting..." }

        session.connect(to: firstTag) { [weak self] (error: Swift.Error?) in
            guard let self = self else { return }  // Keep guard for weak self

            if let error = error {
                print("NFC Connection Error: \(error.localizedDescription)")
                session.invalidate(errorMessage: "Connection failed.")
                Task { @MainActor in self.lastStatusMessage = "Connection failed." }
                return
            }

            print("NFC Tag Connected - Launching FFI Task")
            Task {
                // Note: Accessing firstTag here is okay because the outer function ensures it exists
                // and the session/tag should still be valid at this point.
                guard case .iso7816(let iso7816Tag) = firstTag else {
                    print("Tag is not ISO7816 compatible")
                    await MainActor.run { self.lastStatusMessage = "Card not compatible." }
                    session.invalidate(errorMessage: "Card not compatible.")
                    return
                }

                await MainActor.run { self.lastStatusMessage = "Card connected, getting status..." }

                // --- Create Transport & Call FFI (inside the Task) ---
                let transport = NFCTransport(tag: iso7816Tag)
                do {
                    print("Calling getStatus via FFI...")
                    let status: FfiStatusResponse = try await getStatus(transport: transport)

                    print("FFI getStatus Succeeded:")
                    print("status: \n \(status)")

                    print("  Version: \(status.ver)")
                    print("  Pubkey: \(status.pubkey.hexEncodedString())")

                    await MainActor.run {
                        self.lastStatusResponse = status
                        self.isScanning = false
                        self.didCompleteSuccessfully = true
                        self.showNFCSucceessSheet = true
                    }
                    session.invalidate()

                } catch let error as Error {
                    print("FFI getStatus Failed: \(error)")
                    await MainActor.run {
                        self.lastStatusMessage = "FFI Error: \(error.localizedDescription)"
                    }
                    session.invalidate(errorMessage: "FFI Error.")
                } catch {
                    print("Other getStatus error: \(error)")
                    await MainActor.run {
                        self.lastStatusMessage = "Swift Error: \(error.localizedDescription)"
                    }
                    session.invalidate(errorMessage: "Error.")
                }
            }
        }
    }

    func beginNFCSession() {
        // Invalidate previous session if exists
        tagSession?.invalidate()

        tagSession = NFCTagReaderSession(pollingOption: [.iso14443], delegate: self, queue: nil)
        tagSession?.alertMessage = "Hold your iPhone near the card."
        tagSession?.begin()
        print("NFC Session Started")
    }

}
