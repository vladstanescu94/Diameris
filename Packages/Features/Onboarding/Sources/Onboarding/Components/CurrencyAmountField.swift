import SwiftUI
import DesignSystem

public struct CurrencyAmountField: View {
    @Binding var amount: Decimal
    @Binding var currency: Currency
    let showCurrencyPicker: Bool

    @State private var amountText: String = ""
    @FocusState private var isFocused: Bool

    public init(
        amount: Binding<Decimal>,
        currency: Binding<Currency>,
        showCurrencyPicker: Bool = true
    ) {
        self._amount = amount
        self._currency = currency
        self.showCurrencyPicker = showCurrencyPicker
    }

    public var body: some View {
        HStack(spacing: Spacing.sm) {
            if showCurrencyPicker {
                Menu {
                    ForEach(Currency.allCases) { curr in
                        Button(curr.displayName) {
                            currency = curr
                        }
                    }
                } label: {
                    HStack(spacing: Spacing.xxs) {
                        Text(currency.rawValue)
                            .font(.headline)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                    }
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: CornerRadius.small))
                }
                .buttonStyle(.plain)
            } else {
                Text(currency.rawValue)
                    .font(.headline)
                    .padding(.horizontal, Spacing.sm)
            }

            TextField("0", text: $amountText)
                .font(.title2)
                .fontWeight(.semibold)
                .keyboardType(.decimalPad)
                .focused($isFocused)
                .multilineTextAlignment(.trailing)
                .onChange(of: amountText) { _, newValue in
                    updateAmount(from: newValue)
                }
                .onAppear {
                    if amount > 0 {
                        amountText = formatForEditing(amount)
                    }
                }
        }
        .padding(Spacing.md)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: CornerRadius.medium))
    }

    private func updateAmount(from text: String) {
        let cleaned = text.replacingOccurrences(of: ",", with: ".")
        if let value = Decimal(string: cleaned) {
            amount = value
        } else if text.isEmpty {
            amount = 0
        }
    }

    private func formatForEditing(_ value: Decimal) -> String {
        let number = NSDecimalNumber(decimal: value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.groupingSeparator = ""
        return formatter.string(from: number) ?? "0"
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        CurrencyAmountField(
            amount: .constant(0),
            currency: .constant(.ron)
        )

        CurrencyAmountField(
            amount: .constant(14303),
            currency: .constant(.eur)
        )
    }
    .padding()
}
