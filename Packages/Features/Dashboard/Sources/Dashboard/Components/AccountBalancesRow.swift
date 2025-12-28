import SwiftUI
import DesignSystem
import Domain
import Utilities

/// Compact row displaying account balances.
struct AccountBalancesRow: View {
    let accounts: [DashboardAccount]
    let currency: Currency

    var body: some View {
        if !accounts.isEmpty {
            HStack(spacing: Spacing.sm) {
                ForEach(displayAccounts) { account in
                    accountBadge(for: account)
                }
            }
        }
    }

    /// Filter to only show accounts with balances (savings, personal).
    private var displayAccounts: [DashboardAccount] {
        accounts.filter { account in
            // Show savings and personal accounts
            account.accountType == .savings || account.accountType == .personal
        }
    }
}

// MARK: - Subviews

private extension AccountBalancesRow {
    func accountBadge(for account: DashboardAccount) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Label {
                Text(account.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: account.accountType.icon)
                    .font(.caption)
                    .foregroundStyle(iconColor(for: account.accountType))
            }

            Text(AmountFormatter.formatForDisplay(account.currentBalance, currency: currency.rawValue))
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    func iconColor(for type: AccountType) -> Color {
        switch type {
        case .savings:
            return DiamerisColors.accentPrimary
        case .personal:
            return DiamerisColors.accentSecondary
        case .emergency:
            return DiamerisColors.warning
        default:
            return .secondary
        }
    }
}

#Preview {
    AccountBalancesRow(
        accounts: [
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
        currency: .ron
    )
    .padding()
}
