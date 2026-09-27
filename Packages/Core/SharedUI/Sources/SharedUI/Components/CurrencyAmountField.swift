import SwiftUI
import DesignSystem
import Utilities

/// A text field for entering monetary amounts with currency picker.
public struct CurrencyAmountField: View {
    @Binding var amount: Decimal
    @Binding var currency: Currency
    let showCurrencyPicker: Bool
    let fieldAccessibilityLabel: String?

    @State private var amountText: String = ""
    @FocusState private var isFocused: Bool

    /// - Parameter accessibilityLabel: What VoiceOver calls the amount field (e.g. the account
    ///   name). Pass one whenever a screen shows several amount fields; the default,
    ///   "Amount in RON", is only distinguishable when there is a single field.
    public init(
        amount: Binding<Decimal>,
        currency: Binding<Currency>,
        showCurrencyPicker: Bool = true,
        accessibilityLabel: String? = nil
    ) {
        self._amount = amount
        self._currency = currency
        self.showCurrencyPicker = showCurrencyPicker
        self.fieldAccessibilityLabel = accessibilityLabel
    }

    public var body: some View {
        HStack(spacing: Spacing.sm) {
            currencySelector
            amountTextField
        }
        .padding(Spacing.md)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: CornerRadius.medium))
    }
}

// MARK: - Subviews

private extension CurrencyAmountField {
    @ViewBuilder
    var currencySelector: some View {
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
                        .lineLimit(1)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                }
                .fixedSize(horizontal: true, vertical: false)
            }
            .buttonStyle(.glass)
            .accessibilityLabel(Text("Currency: \(currency.displayName)", bundle: .module, comment: "VoiceOver label for the currency picker; the argument is the currency name"))
            .accessibilityHint(Text("Double tap to change currency", bundle: .module))
        } else {
            Text(currency.rawValue)
                .font(.headline)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, Spacing.sm)
        }
    }

    var amountTextField: some View {
        TextField(Decimal.zero.formatted(), text: $amountText)
            .font(.title2)
            .fontWeight(.semibold)
            .keyboardType(.decimalPad)
            .focused($isFocused)
            .multilineTextAlignment(.trailing)
            .onChange(of: amountText) { _, newValue in
                amount = AmountFormatter.parse(newValue)
            }
            .onChange(of: amount) { _, newValue in
                // The amount can change from outside (presets, imports, reconciliation);
                // don't rewrite what the user is typing when it already parses to this value.
                if AmountFormatter.parse(amountText) != newValue {
                    amountText = AmountFormatter.formatForEditing(newValue)
                }
            }
            .onAppear {
                if amount > 0 {
                    amountText = AmountFormatter.formatForEditing(amount)
                }
            }
            .accessibilityLabel(fieldLabel)
    }

    var fieldLabel: Text {
        if let fieldAccessibilityLabel {
            Text(fieldAccessibilityLabel)
        } else {
            Text("Amount in \(currency.rawValue)", bundle: .module, comment: "VoiceOver label for an amount text field; the argument is a currency code like RON")
        }
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
