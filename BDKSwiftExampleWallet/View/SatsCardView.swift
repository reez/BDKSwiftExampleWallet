//
//  SatsCardView.swift
//  BDKSwiftExampleWallet
//
//  Created by Matthew Ramsden on 5/5/25.
//

import CKTap
import SwiftUI

struct SatsCardView: View {
    let status: FfiStatusResponse?
    @Binding var showNFCSucceessSheet: Bool

    @State private var pubkeyCopied = false
    @State private var nonceCopied = false
    @State private var showPubkeyCheckmark = false
    @State private var showNonceCheckmark = false

    var body: some View {

        if let status = status {

            VStack {

                VStack(spacing: 8) {
                    Image(systemName: "creditcard.fill")
                        .symbolRenderingMode(.hierarchical)
                        .font(.title)
                    Text("SATSCARD")
                        .fontWeight(.semibold)
                }
                .font(.caption)

                Spacer()

                VStack(spacing: 8) {

                    HStack {
                        Text("version: \(status.ver)")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fontDesign(.monospaced)
                    .padding()

                    HStack {
                        HStack(spacing: 0) {
                            Text("pubkey: ")
                            Text(status.pubkey.hexEncodedString())
                                .truncationMode(.middle)
                                .lineLimit(1)
                        }
                        Button {
                            UIPasteboard.general.string = status.pubkey.hexEncodedString()
                            pubkeyCopied = true
                            showPubkeyCheckmark = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                pubkeyCopied = false
                                showPubkeyCheckmark = false
                            }
                        } label: {
                            Image(
                                systemName: showPubkeyCheckmark ? "doc.on.doc.fill" : "doc.on.doc"
                            )
                            .contentTransition(.symbolEffect(.replace))
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fontDesign(.monospaced)
                    .padding()

                    HStack {
                        HStack(spacing: 0) {
                            Text("nonce: ")
                            Text(status.cardNonce.hexEncodedString())
                                .truncationMode(.middle)
                                .lineLimit(1)
                        }
                        Button {
                            UIPasteboard.general.string = status.cardNonce.hexEncodedString()
                            nonceCopied = true
                            showNonceCheckmark = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                nonceCopied = false
                                showNonceCheckmark = false
                            }
                        } label: {
                            Image(systemName: showNonceCheckmark ? "doc.on.doc.fill" : "doc.on.doc")
                                .contentTransition(.symbolEffect(.replace))
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fontDesign(.monospaced)
                    .padding()

                }
                .padding()

                Spacer()

            }
            .padding()
            .padding(.top, 40.0)
        } else {
            VStack {
                ProgressView()
                Text("Loading card details...")
            }
        }
    }
}

#Preview {

    let mockPubkeyHex = "030f15f72cdf8a6718a04a6cd8b4c9d62f43ef7a1a9598atis99b62a5616a17506"
    let mockNonceHex = "ababd8e1bf68deadbeefdeadbeef9090"

    let mockPubkeyData = Data.init(hex: mockPubkeyHex)!
    let mockNonceData = Data.init(hex: mockNonceHex)!

    let mockStatus = FfiStatusResponse(
        proto: 1,
        ver: "1.0.3",
        birth: 1_678_886_400,
        slot0: nil,
        slot1: nil,
        addr: nil,
        tapsigner: false,
        satschip: true,
        path: nil,
        numBackups: 0,
        pubkey: mockPubkeyData,
        cardNonce: mockNonceData,
        testnet: false,
        authDelay: nil
    )

    SatsCardView(status: mockStatus, showNFCSucceessSheet: .constant(true))
}
