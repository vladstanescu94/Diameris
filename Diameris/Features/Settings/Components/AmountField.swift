import SwiftUI
import DesignSystem
import Utilities

/// A labeled decimal amount row. Keeps the typed text (so partial input like "12," survives)
/// and parses it on every keystroke, so the binding is current even if Save is tapped while
/// the field still has focus.
struct AmountField: View {
    let title: String
    @Binding var amount: Decimal
    let currencyCode: String

    @State private var text: String

    init(_ title: String, amount: Binding<Decimal>, currencyCode: String) {
        self.title = title
        _amount = amount
        self.currencyCode = currencyCode
        let initial = amount.wrappedValue
        _text = State(initialValue: initial > 0 ? AmountFormatter.formatForEditing(initial) : "")
    }

    var body: some View {
        LabeledContent(title) {
            HStack(spacing: Spacing.xs) {
                TextField(title, text: $text, prompt: Text(verbatim: "0"))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .onChange(of: text) { _, newValue in
                        amount = AmountFormatter.parse(newValue)
                    }
                Text(currencyCode)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
    }
}
