import SwiftUI
import DesignSystem

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
                    .frame(width: 60)
                    .onChange(of: amountText) { _, newValue in
                        updateAmount(from: newValue)
                    }
                    .onAppear {
                        if amount > 0 {
                            amountText = formatForEditing(amount)
                        }
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
