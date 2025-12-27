import SwiftUI
import DesignSystem
import Utilities

public struct ExpenseRow: View {
    let icon: String
    let name: String
    @Binding var amount: Decimal
    let currency: Currency
    @Binding var linkedAccountId: UUID?
    let accounts: [AccountEntry]

    @State private var amountText: String = ""

    public init(
        icon: String,
        name: String,
        amount: Binding<Decimal>,
        currency: Currency,
        linkedAccountId: Binding<UUID?> = .constant(nil),
        accounts: [AccountEntry] = []
    ) {
        self.icon = icon
        self.name = name
        self._amount = amount
        self.currency = currency
        self._linkedAccountId = linkedAccountId
        self.accounts = accounts
    }

    /// The currently selected account name
    private var selectedAccountName: String {
        if let accountId = linkedAccountId,
           let account = accounts.first(where: { $0.id == accountId }) {
            return account.name
        }
        return "Main".localized
    }

    public var body: some View {
        VStack(spacing: Spacing.xs) {
            mainRow
            if !accounts.isEmpty {
                accountSelector
            }
        }
        .padding(Spacing.md)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: CornerRadius.medium))
        .accessibilityElement(children: .combine)
    }

    private var mainRow: some View {
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
    }

    private var accountSelector: some View {
        HStack {
            Menu {
                // Main account option (nil = primary)
                Button {
                    linkedAccountId = nil
                    HapticManager.selectionChanged()
                } label: {
                    if linkedAccountId == nil {
                        Label("Main".localized, systemImage: "checkmark")
                    } else {
                        Text("Main".localized)
                    }
                }

                Divider()

                // Other accounts
                ForEach(accounts.filter { !$0.isPrimary }) { account in
                    Button {
                        linkedAccountId = account.id
                        HapticManager.selectionChanged()
                    } label: {
                        if linkedAccountId == account.id {
                            Label(account.name, systemImage: "checkmark")
                        } else {
                            Text(account.name)
                        }
                    }
                }
            } label: {
                HStack(spacing: Spacing.xxs) {
                    Text("From:".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(selectedAccountName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(linkedAccountId == nil ? .secondary : DiamerisColors.accentPrimary)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.glass)

            Spacer()
        }
    }
}

#Preview {
    @Previewable @State var linkedId: UUID? = nil
    let accounts = AccountEntry.defaults

    VStack(spacing: Spacing.sm) {
        ExpenseRow(
            icon: "cart.fill",
            name: "Food & Groceries",
            amount: .constant(3000),
            currency: .ron,
            linkedAccountId: $linkedId,
            accounts: accounts
        )

        ExpenseRow(
            icon: "house.fill",
            name: "Rent / Housing",
            amount: .constant(0),
            currency: .eur,
            linkedAccountId: .constant(nil),
            accounts: accounts
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
