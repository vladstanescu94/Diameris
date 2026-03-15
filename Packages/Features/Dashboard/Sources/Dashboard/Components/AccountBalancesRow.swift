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
        GlassEffectContainer(spacing: Spacing.sm) {
            VStack(spacing: Spacing.sm) {
                Label {
                    Text("Account Balances".localized)
                        .font(.headline)
                } icon: {
                    Image(systemName: "building.columns.fill")
                        .foregroundStyle(DiamerisColors.accentPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if let primary = primaryAccount {
                    PrimaryAccountCard(account: primary, currency: currency)
                }

                if !otherAccounts.isEmpty {
                    LazyVGrid(columns: gridColumns, spacing: Spacing.sm) {
                        ForEach(otherAccounts) { account in
                            SecondaryAccountCard(account: account, currency: currency)
                        }
                    }
                }
            }
        }
    }

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: Spacing.sm),
            GridItem(.flexible(), spacing: Spacing.sm)
        ]
    }
}

// MARK: - Primary Account Card

private struct PrimaryAccountCard: View {
    let account: DashboardAccount
    let currency: Currency

    var body: some View {
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
                    .bold()
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
}

// MARK: - Secondary Account Card

private struct SecondaryAccountCard: View {
    let account: DashboardAccount
    let currency: Currency

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Label {
                Text(account.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } icon: {
                Image(systemName: account.accountType.icon)
                    .font(.caption)
                    .foregroundStyle(iconColor)
            }

            Text(AmountFormatter.formatForDisplay(account.currentBalance, currency: currency.rawValue))
                .font(.subheadline)
                .bold()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private var iconColor: Color {
        switch account.accountType {
        case .primary, .savings:
            DiamerisColors.accentPrimary
        case .personal:
            DiamerisColors.accentSecondary
        case .joint:
            .purple
        case .emergency:
            DiamerisColors.warning
        case .other:
            .secondary
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
