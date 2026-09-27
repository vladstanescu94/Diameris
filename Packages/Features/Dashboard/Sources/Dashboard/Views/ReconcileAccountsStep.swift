import SwiftUI
import DesignSystem
import SharedUI
import Domain
import Utilities

struct ReconcileAccountsStep: View {
    @Bindable var flow: NewMonthFlowModel
    let currency: Currency
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            VStack(spacing: Spacing.sm) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .iconLg()
                    .foregroundStyle(DiamerisColors.accentSecondary)
                    .accessibilityHidden(true)

                Text("Update your account balances".localized)
                    .font(.title3)
                    .bold()
                    .accessibilityAddTraits(.isHeader)

                Text("Enter the current balance of each account.".localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, Spacing.lg)

            ScrollView {
                VStack(spacing: Spacing.md) {
                    ForEach(flow.reconcilableAccounts) { account in
                        ReconcileAccountCard(
                            account: account,
                            balance: $flow[balanceFor: account.id],
                            currency: currency
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
            .tint(DiamerisColors.accentPrimaryFill)
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
    let currency: Currency

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ViewThatFits(in: .horizontal) {
                HStack {
                    accountLabel
                    Spacer()
                    currentBalanceCaption
                }
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    accountLabel
                    currentBalanceCaption
                }
            }

            CurrencyAmountField(
                amount: $balance,
                currency: .constant(currency),
                showCurrencyPicker: false,
                accessibilityLabel: account.name
            )

            Text(String(localized: "was \(AmountFormatter.formatForDisplay(account.currentBalance, currency: currency.rawValue)) last month", bundle: .module))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .glassCard()
    }

    private var accountLabel: some View {
        Label {
            Text(account.name)
                .font(.headline)
        } icon: {
            Image(systemName: account.accountType.icon)
                .foregroundStyle(account.accountType.color)
        }
    }

    private var currentBalanceCaption: some View {
        Text("Current balance".localized)
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}

#Preview {
    let dashboard = DashboardViewModel()
    dashboard.accounts = [
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
    ]

    return ReconcileAccountsStep(
        flow: NewMonthFlowModel(dashboard: dashboard),
        currency: .ron,
        onContinue: {}
    )
}
