import SwiftUI
import DesignSystem
import Utilities

/// The main Dashboard tab view showing financial summary and actions.
public struct DashboardView: View {
    @Bindable var viewModel: DashboardViewModel
    var onDevToolsTapped: (() -> Void)?

    public init(viewModel: DashboardViewModel, onDevToolsTapped: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onDevToolsTapped = onDevToolsTapped
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                dashboardBody
            }
            .navigationTitle(viewModel.currentMonthDisplay)
            .toolbar {
                devToolsButton
            }
        }
    }
}

// MARK: - Toolbar

private extension DashboardView {
    @ToolbarContentBuilder
    var devToolsButton: some ToolbarContent {
        if let onDevToolsTapped {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    onDevToolsTapped()
                } label: {
                    Image(systemName: "hammer.fill")
                }
            }
        }
    }
}

// MARK: - Content

private extension DashboardView {
    @ViewBuilder
    var dashboardBody: some View {
        if viewModel.hasCompletedOnboarding {
            dashboardContent
        } else {
            emptyState
        }
    }

    var dashboardContent: some View {
        VStack(spacing: Spacing.md) {
            // Financial Summary
            SummaryCard(
                income: viewModel.monthlyIncome,
                expenses: viewModel.totalExpenses,
                available: viewModel.availableIncome,
                currency: viewModel.currency
            )

            // Emergency Fund Progress (if exists)
            if let emergencyAccount = viewModel.emergencyAccount,
               let progress = viewModel.emergencyProgress,
               let target = viewModel.emergencyTarget {
                EmergencyProgressCard(
                    currentBalance: emergencyAccount.currentBalance,
                    target: target,
                    progress: progress,
                    multiplier: emergencyAccount.emergencyMultiplier ?? 3.0,
                    currency: viewModel.currency
                )
            }

            // Account Balances
            AccountBalancesSection(
                accounts: viewModel.accounts,
                currency: viewModel.currency
            )

            // Expense Breakdown
            ExpenseBreakdownCard(
                expenses: viewModel.expenses,
                currency: viewModel.currency
            )
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    var emptyState: some View {
        ContentUnavailableView {
            Label("No data yet".localized, systemImage: "chart.bar.doc.horizontal")
        } description: {
            Text("Complete onboarding to start tracking your finances".localized)
        }
    }
}

#Preview {
    let viewModel = DashboardViewModel()
    viewModel.userName = "Vlad"
    viewModel.monthlyIncome = 14303
    viewModel.currency = .ron
    viewModel.hasCompletedOnboarding = true
    viewModel.accounts = [
        DashboardAccount(
            id: UUID(),
            name: "BT",
            accountType: .primary,
            isPrimary: true,
            isPrimarySavings: false,
            emergencyMultiplier: nil,
            currentBalance: 5000
        ),
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
    viewModel.expenses = [
        DashboardExpense(id: UUID(), name: "Auto", amount: 3600, icon: "car.fill", linkedAccountId: nil),
        DashboardExpense(id: UUID(), name: "Food", amount: 3000, icon: "cart.fill", linkedAccountId: nil),
        DashboardExpense(id: UUID(), name: "Subscriptions", amount: 605, icon: "creditcard.fill", linkedAccountId: nil)
    ]

    return ScrollView {
        DashboardView(viewModel: viewModel)
    }
}
