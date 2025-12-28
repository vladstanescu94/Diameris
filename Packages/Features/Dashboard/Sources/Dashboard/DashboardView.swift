import SwiftUI
import DesignSystem
import Utilities

/// The main Dashboard tab view showing financial summary and actions.
public struct DashboardView: View {
    @Bindable var viewModel: DashboardViewModel

    public init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle(viewModel.currentMonthDisplay)
                .sheet(isPresented: $viewModel.showNewMonthSheet) {
                    NewMonthSheet(viewModel: viewModel)
                }
        }
    }
}

// MARK: - Content

private extension DashboardView {
    @ViewBuilder
    var content: some View {
        if viewModel.hasCompletedOnboarding {
            dashboardContent
        } else {
            emptyState
        }
    }

    var dashboardContent: some View {
        ScrollView {
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

                // New Month Button
                newMonthButton
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
    }

    var emptyState: some View {
        ContentUnavailableView {
            Label("No data yet".localized, systemImage: "chart.bar.doc.horizontal")
        } description: {
            Text("Complete onboarding to start tracking your finances".localized)
        }
    }

    var newMonthButton: some View {
        Button {
            viewModel.openNewMonthFlow()
        } label: {
            VStack(spacing: Spacing.xs) {
                Label("New Month".localized, systemImage: "calendar.badge.plus")
                    .font(.headline)

                Text("Process this month's salary".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
        }
        .buttonStyle(.glassProminent)
    }
}

#Preview {
    let viewModel = DashboardViewModel()
    // Simulate loaded data
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

    return DashboardView(viewModel: viewModel)
}
