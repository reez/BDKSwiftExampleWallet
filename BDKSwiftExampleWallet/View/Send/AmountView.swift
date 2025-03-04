//
//  AmountView.swift
//  BDKSwiftExampleWallet
//
//  Created by Matthew Ramsden on 9/15/23.
//

import BitcoinUI
import SwiftUI

struct AmountView: View {
    @Bindable var viewModel: AmountViewModel
    @Binding var navigationPath: NavigationPath
    @State var numpadAmount = "0"
    let address: String
    var isSmallDevice: Bool {
        UIScreen.main.isPhoneSE
    }

    var body: some View {

        ZStack {
            Color(uiColor: .systemBackground)

            VStack(spacing: 50) {
                Spacer()
                VStack(spacing: 4) {
                    Text("\(numpadAmount.formattedWithSeparator) sats")
                        .textStyle(BitcoinTitle1())
                        .contentTransition(.numericText())
                        .animation(.default, value: numpadAmount)
                    if let balance = viewModel.balanceTotal {
                        HStack(spacing: 2) {
                            Text(balance.delimiter)
                            Text("total")
                        }
                        .fontWeight(.semibold)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    if let balance = viewModel.balanceConfirmed {
                        HStack(spacing: 2) {
                            Text(balance.delimiter)
                            Text("confirmed")
                        }
                        .fontWeight(.semibold)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                GeometryReader { geometry in
                    let buttonDivider: CGFloat = isSmallDevice ? 5 : 4
                    let buttonSize = geometry.size.width / buttonDivider
                    let spacingDivider: CGFloat = isSmallDevice ? 12 : 10
                    VStack(spacing: buttonSize / spacingDivider) {
                        numpadRow(["1", "2", "3"], buttonSize: buttonSize)
                        numpadRow(["4", "5", "6"], buttonSize: buttonSize)
                        numpadRow(["7", "8", "9"], buttonSize: buttonSize)
                        numpadRow([" ", "0", "<"], buttonSize: buttonSize)
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(height: isSmallDevice ? 200 : 300)

                Spacer()

                VStack {

                    Button {
                        navigationPath.append(
                            NavigationDestination.fee(amount: numpadAmount, address: address)
                        )
                    } label: {
                        Label(
                            title: { Text("Next") },
                            icon: { Image(systemName: "arrow.right") }
                        )
                        .labelStyle(.iconOnly)
                    }
                    .buttonStyle(
                        BitcoinOutlined(
                            width: 100,
                            tintColor: .primary,
                            isCapsule: true
                        )
                    )

                }

            }
            .padding()
            .task {
                viewModel.getBalance()
            }
        }
        .onChange(of: navigationPath) { oldPath, newPath in
            if newPath.isEmpty {
                numpadAmount = "0"
            }
        }
        .alert(isPresented: $viewModel.showingAmountViewErrorAlert) {
            Alert(
                title: Text("Amount Error"),
                message: Text(viewModel.amountViewError?.description ?? "Unknown"),
                dismissButton: .default(Text("OK")) {
                    viewModel.amountViewError = nil
                }
            )
        }

    }

}

extension AmountView {
    func numpadRow(_ characters: [String], buttonSize: CGFloat) -> some View {
        HStack(spacing: buttonSize / 2) {
            ForEach(characters, id: \.self) { character in
                NumpadButton(numpadAmount: $numpadAmount, character: character)
                    .frame(width: buttonSize, height: buttonSize)
            }
        }
    }
}

struct NumpadButton: View {
    @Binding var numpadAmount: String
    var character: String

    var body: some View {
        Button {
            if character == "<" {
                if numpadAmount.count > 1 {
                    numpadAmount.removeLast()
                } else {
                    numpadAmount = "0"
                }
            } else if character == " " {
                return
            } else {
                if numpadAmount == "0" {
                    numpadAmount = character
                } else {
                    numpadAmount.append(character)
                }
            }
        } label: {
            Text(character).textStyle(BitcoinTitle3())
        }
    }
}

#if DEBUG
    #Preview {
        AmountView(
            viewModel: .init(bdkClient: .mock),
            navigationPath: .constant(NavigationPath()),
            address: "address"
        )
    }
#endif
