import SwiftUI
import DesignSystem
import Utilities

public struct ExpenseRow: View {
    let icon: String
    let name: String
    @Binding var amount: Decimal
    let currency: Currency

    @State private var amountText: String = ""

    public init(
        icon: String,
        name: String,
        amount: Binding<Decimal>,
        currency: Currency
    ) {
        self.icon = icon
        self.name = name
        self._amount = amount
        self.currency = currency
    }

    public var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: ComponentSize.iconContainer)
                .accessibilityHidden(true)

            Text(name)
                .font(.body)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: Spacing.sm)

            HStack(spacing: Spacing.xs) {
                Text(currency.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("0", text: $amountText)
                    .font(.body)
                    .fontWeight(.medium)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: ComponentSize.amountInputWidth)
                    .onChange(of: amountText) { _, newValue in
                        amount = AmountFormatter.parse(newValue)
                    }
                    .onAppear {
                        if amount > 0 {
                            amountText = AmountFormatter.formatForEditing(amount)
                        }
                    }
                    .accessibilityLabel(String(localized: "\(name) amount", bundle: .module))
            }
        }
        .padding(Spacing.md)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: CornerRadius.medium))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: Spacing.sm) {
        ExpenseRow(
            icon: "cart.fill",
            name: "Food & Groceries",
            amount: .constant(3000),
            currency: .ron
        )

        ExpenseRow(
            icon: "house.fill",
            name: "Rent / Housing",
            amount: .constant(0),
            currency: .eur
        )

        ExpenseRow(
            icon: "car.fill",
            name: "Transportation & Fuel",
            amount: .constant(500),
            currency: .usd
        )
    }
    .padding()
}
