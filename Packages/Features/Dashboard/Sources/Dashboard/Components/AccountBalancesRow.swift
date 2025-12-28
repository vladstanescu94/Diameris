import SwiftUI
import DesignSystem
import Domain
import Utilities

/// Section displaying all account balances.
struct AccountBalancesSection: View {
    let accounts: [DashboardAccount]
    let currency: Currency

    /// Primary account (where salary lands)
    private var primaryAccount: DashboardAccount? {
        accounts.first { $0.isPrimary }
    }

    /// Other accounts excluding primary and emergency (emergency has its own card)
    private var otherAccounts: [DashboardAccount] {
        accounts.filter { account in
            !account.isPrimary && account.accountType != .emergency
        }
    }

    var body: some View {
        VStack(spacing: Spacing.sm) {
            sectionHeader

            if let primary = primaryAccount {
                primaryAccountCard(primary)
            }

            if !otherAccounts.isEmpty {
                otherAccountsGrid
            }
        }
    }
}

// MARK: - Subviews

private extension AccountBalancesSection {
    var sectionHeader: some View {
        Label {
            Text("Account Balances".localized)
                .font(.headline)
        } icon: {
            Image(systemName: "building.columns.fill")
                .foregroundStyle(DiamerisColors.accentPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func primaryAccountCard(_ account: DashboardAccount) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Label {
                    Text(account.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: account.accountType.icon)
                        .font(.subheadline)
                        .foregroundStyle(DiamerisColors.accentPrimary)
                }

                Text(AmountFormatter.formatForDisplay(account.currentBalance, currency: currency.rawValue))
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Spacer()

            Text("Primary".localized)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
                .background(Color.secondary.opacity(Opacity.faint), in: Capsule())
        }
        .glassCard()
    }

    var otherAccountsGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: Spacing.sm) {
            ForEach(otherAccounts) { account in
                accountCard(account)
            }
        }
    }

    var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: Spacing.sm),
            GridItem(.flexible(), spacing: Spacing.sm)
        ]
    }

    func accountCard(_ account: DashboardAccount) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Label {
                Text(account.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } icon: {
                Image(systemName: account.accountType.icon)
                    .font(.caption)
                    .foregroundStyle(iconColor(for: account.accountType))
            }

            Text(AmountFormatter.formatForDisplay(account.currentBalance, currency: currency.rawValue))
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    func iconColor(for type: AccountType) -> Color {
        switch type {
        case .primary:
            return DiamerisColors.accentPrimary
        case .savings:
            return DiamerisColors.accentPrimary
        case .personal:
            return DiamerisColors.accentSecondary
        case .joint:
            return .purple
        case .emergency:
            return DiamerisColors.warning
        case .other:
            return .secondary
        }
    }
}

#Preview {
    AccountBalancesSection(
        accounts: [
            DashboardAccount(
                id: UUID(),
                name: "BT Checking",
                accountType: .primary,
                isPrimary: true,
                isPrimarySavings: false,
                emergencyMultiplier: nil,
                currentBalance: 5000
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
            ),
            DashboardAccount(
                id: UUID(),
                name: "Joint",
                accountType: .joint,
                isPrimary: false,
                isPrimarySavings: false,
                emergencyMultiplier: nil,
                currentBalance: 3000
            )
        ],
        currency: .ron
    )
    .padding()
}
