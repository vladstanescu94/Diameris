import SwiftUI
import SwiftData
import DesignSystem
import Dashboard
import Domain
import Utilities
import Onboarding

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @Query private var accounts: [Account]
    @Query private var expenses: [Expense]
    @Query private var savingsAllocations: [SavingsAllocation]

    @State private var dashboardViewModel = DashboardViewModel()

    private var userProfile: UserProfile? { userProfiles.first }
    private var savingsAllocation: SavingsAllocation? { savingsAllocations.first }

    var body: some View {
        TabView {
            DashboardView(viewModel: dashboardViewModel)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.pie.fill")
                }

            BudgetPlaceholder()
                .tabItem {
                    Label("Budget", systemImage: "list.bullet.rectangle")
                }

            GoalsPlaceholder()
                .tabItem {
                    Label("Goals", systemImage: "target")
                }

            TransfersPlaceholder()
                .tabItem {
                    Label("Transfers", systemImage: "arrow.left.arrow.right")
                }

            #if DEBUG
            DevDebugView()
                .tabItem {
                    Label("Dev", systemImage: "hammer.fill")
                }
            #endif
        }
        .onAppear {
            loadDashboardData()
        }
        .onChange(of: userProfiles) { _, _ in
            loadDashboardData()
        }
        .onChange(of: accounts) { _, _ in
            loadDashboardData()
        }
        .onChange(of: expenses) { _, _ in
            loadDashboardData()
        }
        .onChange(of: savingsAllocations) { _, _ in
            loadDashboardData()
        }
    }

    private func loadDashboardData() {
        guard let profile = userProfile else {
            dashboardViewModel.hasCompletedOnboarding = false
            return
        }

        // Get currency from profile
        let currency = Currency(rawValue: profile.currencyCode) ?? .ron

        // Get income from query or default
        let income = fetchMonthlyIncome()

        // Convert accounts to DashboardAccount
        let dashboardAccounts = accounts.map { account in
            DashboardAccount(
                id: account.id,
                name: account.name,
                accountType: account.accountType,
                isPrimary: account.isPrimary,
                isPrimarySavings: account.isPrimarySavings,
                emergencyMultiplier: account.emergencyMultiplier,
                currentBalance: account.currentBalance
            )
        }

        // Convert expenses to DashboardExpense
        let dashboardExpenses = expenses.filter { $0.isEnabled }.map { expense in
            DashboardExpense(
                id: expense.id,
                name: expense.name,
                amount: expense.amount,
                icon: expense.icon,
                linkedAccountId: expense.linkedAccountId
            )
        }

        // Get savings allocation
        let allocation = savingsAllocation

        // Update the view model
        dashboardViewModel.userName = profile.name
        dashboardViewModel.monthlyIncome = income
        dashboardViewModel.currency = currency
        dashboardViewModel.accounts = dashboardAccounts
        dashboardViewModel.expenses = dashboardExpenses
        dashboardViewModel.savingsPercentage = allocation?.percentage ?? 0.25
        dashboardViewModel.savingsBoostEnabled = allocation?.boostEnabled ?? false
        dashboardViewModel.savingsBoostMultiplier = allocation?.boostMultiplier ?? 3.0
        dashboardViewModel.remainingMoneyDestination = profile.remainingMoneyDestination
        dashboardViewModel.hasCompletedOnboarding = true
    }

    private func fetchMonthlyIncome() -> Decimal {
        let descriptor = FetchDescriptor<Income>()
        let incomes = try? modelContext.fetch(descriptor)
        return incomes?.first?.amount ?? 0
    }
}

// MARK: - Placeholder Views

private struct BudgetPlaceholder: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                Image(systemName: "list.bullet.rectangle")
                    .iconXxl()
                    .foregroundStyle(DiamerisColors.accentSecondaryLight)

                Text("Budget")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Coming soon")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Budget")
        }
    }
}

private struct GoalsPlaceholder: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                Image(systemName: "target")
                    .iconXxl()
                    .foregroundStyle(DiamerisColors.accentPrimaryLight)

                Text("Goals")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Coming soon")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Goals")
        }
    }
}

private struct TransfersPlaceholder: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                Image(systemName: "arrow.left.arrow.right")
                    .iconXxl()
                    .foregroundStyle(DiamerisColors.accentSecondaryLight)

                Text("Transfers")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Coming soon")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Transfers")
        }
    }
}

#Preview {
    MainTabView()
}
