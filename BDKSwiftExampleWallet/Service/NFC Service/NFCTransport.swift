//
//  NFCTransport.swift
//  BDKSwiftExampleWallet
//
//  Created by Matthew Ramsden on 5/5/25.
//

import CKTap
import CoreNFC
import Foundation

final class NFCTransport: NSObject, CkTransportFfi {

    private let tag: NFCISO7816Tag

    init(tag: NFCISO7816Tag) {
        self.tag = tag
        print("NFCTransport initialized with tag.")
    }

    func transmitApdu(commandApdu: Data) throws -> Data {
        print("NFCTransport: Will send APDU: \(commandApdu.hexEncodedString())")

        let iso7816Apdu = NFCISO7816APDU(data: commandApdu)!  // Force unwrap for simplicity, handle nil in production

        var responseData: Data?
        var responseError: Swift.Error?
        let semaphore = DispatchSemaphore(value: 0)

        tag.sendCommand(apdu: iso7816Apdu) { (data, sw1, sw2, error) in
            if let error = error {
                print("NFCTransport: Error sending APDU: \(error.localizedDescription)")
                responseError = error
            } else {
                var response = data
                response.append(sw1)
                response.append(sw2)
                print("NFCTransport: Received response: \(response.hexEncodedString())")
                responseData = response
            }
            semaphore.signal()
        }

        _ = semaphore.wait(timeout: .now() + 15.0)

        if let error = responseError {
            throw Error.Transport(msg: "NFC Error: \(error.localizedDescription)")
        }

        guard let data = responseData else {
            throw Error.Transport(msg: "NFC command timed out or returned no data.")
        }

        // Check (simplistic) for 90 00 (OK)
        // TODO: proper status word handling.
        if data.suffix(2) != Data([0x90, 0x00]) {
            print(
                "NFCTransport: Warning - Command received non-OK status: \(data.suffix(2).hexEncodedString())"
            )
            // For now, we pass it through, Rust's parsing will likely fail if it wasn't expecting this status.
        }

        return data  // Return full response data (including SW1, SW2)
    }
}
