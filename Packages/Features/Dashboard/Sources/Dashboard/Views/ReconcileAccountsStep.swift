import SwiftUI
import DesignSystem
import SharedUI
import Domain
import Utilities

/// Step 2: Update account balances.
struct ReconcileAccountsStep: View {
    let accounts: [DashboardAccount]
    @Binding var balances: [UUID: Decimal]
    let currency: Currency
    let onContinue: () -> Void

    @State private var currencyBinding: Currency

    init(
        accounts: [DashboardAccount],
        balances: Binding<[UUID: Decimal]>,
        currency: Currency,
        onContinue: @escaping () -> Void
    ) {
        self.accounts = accounts
        self._balances = balances
        self.currency = currency
        self.onContinue = onContinue
        self._currencyBinding = State(initialValue: currency)
    }

    /// Accounts that need reconciliation (emergency, savings, personal).
    private var reconcilableAccounts: [DashboardAccount] {
        accounts.filter { account in
            account.accountType == .emergency ||
            account.accountType == .savings ||
            account.accountType == .personal
        }
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            VStack(spacing: Spacing.sm) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .iconLg()
                    .foregroundStyle(DiamerisColors.accentSecondary)

                Text("Update your account balances".localized)
                    .font(.title3)
                    .bold()

                Text("Did you use any savings this month?".localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, Spacing.lg)

            ScrollView {
                VStack(spacing: Spacing.md) {
                    ForEach(reconcilableAccounts) { account in
                        ReconcileAccountCard(
                            account: account,
                            balance: Binding(
                                get: { balances[account.id] ?? account.currentBalance },
                                set: { balances[account.id] = $0 }
                            ),
                            currency: $currencyBinding
                        )
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
            .scrollIndicators(.hidden)

            Button(action: onContinue) {
                Text("Continue".localized)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.glassProminent)
            .padding(.horizontal, Spacing.lg)
        }
        .padding(.vertical, Spacing.md)
        .contentShape(Rectangle())
        .onTapGesture {
            KeyboardHelper.dismiss()
        }
    }
}

// MARK: - Reconcile Account Card

private struct ReconcileAccountCard: View {
    let account: DashboardAccount
    @Binding var balance: Decimal
    @Binding var currency: Currency

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Label {
                    Text(account.name)
                        .font(.headline)
                } icon: {
                    Image(systemName: account.accountType.icon)
                        .foregroundStyle(iconColor)
                }

                Spacer()

                Text("Current balance".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            CurrencyAmountField(
                amount: $balance,
                currency: $currency,
                showCurrencyPicker: false
            )

            Text(String(localized: "was \(AmountFormatter.formatForDisplay(account.currentBalance, currency: currency.rawValue)) last month", bundle: .module))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .glassCard()
    }

    private var iconColor: Color {
        switch account.accountType {
        case .emergency: DiamerisColors.warning
        case .savings: DiamerisColors.accentPrimary
        case .personal: DiamerisColors.accentSecondary
        default: .secondary
        }
    }
}

#Preview {
    ReconcileAccountsStep(
        accounts: [
            DashboardAccount(
                id: UUID(),
                name: "Emergency",
                accountType: .emergency,
                isPrimary: false,
                isPrimarySavings: false,
                emergencyMultiplier: 3.0,
                currentBalance: 37056
            ),
            DashboardAccount(
                id: UUID(),
                name: "Savings",
                accountType: .savings,
                isPrimary: false,
                isPrimarySavings: true,
                emergencyMultiplier: nil,
                currentBalance: 5200
            ),
            DashboardAccount(
                id: UUID(),
                name: "Personal",
                accountType: .personal,
                isPrimary: false,
                isPrimarySavings: false,
                emergencyMultiplier: nil,
                currentBalance: 1500
            )
        ],
        balances: .constant([:]),
        currency: .ron,
        onContinue: {}
    )
}
