import SwiftUI
import DesignSystem
import Domain
import SharedUI
import Utilities

struct AccountBalancesSection: View {
    let accounts: [DashboardAccount]
    let currency: Currency

    private var primaryAccount: DashboardAccount? {
        accounts.first { $0.isPrimary }
    }

    /// Excludes emergency, which has its own card.
    private var otherAccounts: [DashboardAccount] {
        accounts.filter { account in
            !account.isPrimary && account.accountType != .emergency
        }
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Label {
                Text("Account Balances".localized)
                    .font(.headline)
            } icon: {
                Image(systemName: "building.columns.fill")
                    .foregroundStyle(DiamerisColors.accentPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)

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

    /// Two columns normally; one column at accessibility text sizes so balances aren't squeezed.
    private var gridColumns: [GridItem] {
        let columnCount = dynamicTypeSize.isAccessibilitySize ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: columnCount)
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
                        .foregroundStyle(account.accountType.color)
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
        .accessibilityElement(children: .combine)
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
            } icon: {
                Image(systemName: account.accountType.icon)
                    .font(.caption)
                    .foregroundStyle(account.accountType.color)
            }

            Text(AmountFormatter.formatForDisplay(account.currentBalance, currency: currency.rawValue))
                .font(.subheadline)
                .bold()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .glassCard()
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
