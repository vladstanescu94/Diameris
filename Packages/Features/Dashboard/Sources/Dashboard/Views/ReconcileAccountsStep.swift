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
            headerSection

            ScrollView {
                VStack(spacing: Spacing.md) {
                    ForEach(reconcilableAccounts) { account in
                        accountBalanceCard(for: account)
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
            .scrollIndicators(.hidden)

            continueButton
                .padding(.horizontal, Spacing.lg)
        }
        .padding(.vertical, Spacing.md)
    }
}

// MARK: - Subviews

private extension ReconcileAccountsStep {
    var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .iconLg()
                .foregroundStyle(DiamerisColors.accentSecondary)

            Text("Update your account balances".localized)
                .font(.title3)
                .fontWeight(.semibold)

            Text("Did you use any savings this month?".localized)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, Spacing.lg)
    }

    func accountBalanceCard(for account: DashboardAccount) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Account header
            Label {
                Text(account.name)
                    .font(.headline)
            } icon: {
                Image(systemName: account.accountType.icon)
                    .foregroundStyle(iconColor(for: account.accountType))
            }

            // Balance input
            HStack {
                Text("Current balance".localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                balanceInput(for: account)
            }

            // Previous balance hint
            previousBalanceHint(for: account)
        }
        .glassCard()
    }

    func balanceInput(for account: DashboardAccount) -> some View {
        let binding = Binding<Decimal>(
            get: { balances[account.id] ?? account.currentBalance },
            set: { balances[account.id] = $0 }
        )

        return CurrencyAmountField(
            amount: binding,
            currency: $currencyBinding,
            showCurrencyPicker: false
        )
        .frame(width: ComponentSize.balanceInputWidth)
    }

    func previousBalanceHint(for account: DashboardAccount) -> some View {
        let formatted = AmountFormatter.formatForDisplay(
            account.currentBalance,
            currency: currency.rawValue
        )

        return Text(String(localized: "was \(formatted) last month", bundle: .module))
            .font(.caption)
            .foregroundStyle(.tertiary)
    }

    func iconColor(for type: AccountType) -> Color {
        switch type {
        case .emergency:
            return DiamerisColors.warning
        case .savings:
            return DiamerisColors.accentPrimary
        case .personal:
            return DiamerisColors.accentSecondary
        default:
            return .secondary
        }
    }

    var continueButton: some View {
        Button {
            onContinue()
        } label: {
            Text("Continue".localized)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.glassProminent)
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
