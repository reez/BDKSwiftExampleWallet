//
//  TransactionListHeaderView.swift
//  BDKSwiftExampleWallet
//
//  Created by Rubens Machion on 24/04/25.
//

import SwiftUI

struct ActivityHomeHeaderView: View {

    let walletSyncState: WalletSyncState
    let progress: Float
    let inspectedScripts: UInt64
    let totalScripts: UInt64
    let needsFullScan: Bool

    let showAllTransactions: () -> Void

    var body: some View {
        HStack {
            Text("Activity")
            Spacer()

            HStack {
                if needsFullScan {
                    Text("\(inspectedScripts)")
                        .padding(.trailing, -5.0)
                        .fontWeight(.semibold)
                        .contentTransition(.numericText())
                        .transition(.opacity)
                        .fontDesign(.monospaced)
                        .foregroundStyle(.secondary)
                        .font(.caption2)
                        .fontWeight(.thin)
                        .animation(.easeInOut, value: inspectedScripts)
                } else if walletSyncState == .syncing {
                    HStack {
                        if progress < 1.0 {
                            Text("\(inspectedScripts)")
                                .padding(.trailing, -5.0)
                                .fontWeight(.semibold)
                                .contentTransition(.numericText())
                                .transition(.opacity)

                            Text("/")
                                .padding(.trailing, -5.0)
                                .transition(.opacity)
                            Text("\(totalScripts)")
                                .contentTransition(.numericText())
                                .transition(.opacity)
                        }

                        Text(
                            String(
                                format: "%.0f%%",
                                progress * 100
                            )
                        )
                        .contentTransition(.numericText())
                        .transition(.opacity)
                    }
                    .fontDesign(.monospaced)
                    .foregroundStyle(.secondary)
                    .font(.caption2)
                    .fontWeight(.thin)
                    .animation(.easeInOut, value: inspectedScripts)
                    .animation(.easeInOut, value: totalScripts)
                    .animation(.easeInOut, value: progress)
                }
            }
            HStack {
                HStack(spacing: 5) {
                    self.syncImageIndicator()
                }
                .contentTransition(.symbolEffect(.replace.offUp))

            }
            .foregroundStyle(.secondary)
            .font(.caption)

            if walletSyncState == .synced {
                Button {
                    self.showAllTransactions()
                } label: {
                    HStack(spacing: 2) {
                        Text("Show All")
                        Image(systemName: "arrow.right")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fontWeight(.regular)
                }
            }
        }
        .fontWeight(.bold)
    }

    @ViewBuilder
    private func syncImageIndicator() -> some View {
        switch walletSyncState {
        case .synced:
            AnyView(
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            )

        case .syncing:
            AnyView(
                Image(systemName: "slowmo")
                    .symbolEffect(
                        .variableColor.cumulative
                    )
            )

        case .notStarted:
            AnyView(
                Image(systemName: "arrow.clockwise")
            )
        default:
            AnyView(
                Image(
                    systemName: "person.crop.circle.badge.exclamationmark"
                )
            )
        }
    }
}
