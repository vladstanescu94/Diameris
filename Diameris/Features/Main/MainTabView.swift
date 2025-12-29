import SwiftUI
import SwiftData
import DesignSystem
import Dashboard
import Domain
import Utilities
import Onboarding
import Expenses

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @Query private var accounts: [Account]
    @Query private var expenses: [Expense]
    @Query private var savingsAllocations: [SavingsAllocation]

    @State private var dashboardViewModel = DashboardViewModel()
    @State private var expensesViewModel = ExpensesViewModel()
    @State private var showSettings = false

    #if DEBUG
    @State private var showDevTools = false
    #endif

    private var userProfile: UserProfile? { userProfiles.first }
    private var savingsAllocation: SavingsAllocation? { savingsAllocations.first }

    var body: some View {
        TabView {
            Tab("Dashboard".localized, systemImage: "chart.pie.fill") {
                DashboardView(
                    viewModel: dashboardViewModel,
                    onSettingsTapped: { showSettings = true },
                    onDevToolsTapped: devToolsTappedHandler
                )
            }

            Tab("Expenses".localized, systemImage: "list.bullet.rectangle") {
                ExpenseListView(viewModel: expensesViewModel)
            }

            Tab("Insights".localized, systemImage: "lightbulb.max") {
                InsightsPlaceholder()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory {
            newMonthAccessoryButton
        }
        .sheet(isPresented: $dashboardViewModel.showNewMonthSheet) {
            NewMonthSheet(viewModel: dashboardViewModel)
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
        }
        .onChange(of: showSettings) { _, isShowing in
            if !isShowing {
                loadDashboardData()
            }
        }
        #if DEBUG
        .sheet(isPresented: $showDevTools) {
            DevDebugView()
        }
        #endif
        .onAppear {
            loadDashboardData()
            loadExpensesData()
            setupExpensesCallbacks()
        }
        .onChange(of: userProfiles) { _, _ in
            loadDashboardData()
            loadExpensesData()
        }
        .onChange(of: accounts) { _, _ in
            loadDashboardData()
        }
        .onChange(of: expenses) { _, _ in
            loadDashboardData()
            loadExpensesData()
        }
        .onChange(of: savingsAllocations) { _, _ in
            loadDashboardData()
        }
    }

    // MARK: - Tab Bar Accessory

    private var newMonthAccessoryButton: some View {
        Button {
            dashboardViewModel.openNewMonthFlow()
        } label: {
            HStack {
                Image(systemName: "calendar.badge.plus")
                Text("New Month".localized)
            }
            .frame(maxWidth: .infinity)
            .contentShape(.rect)
        }
        .disabled(!dashboardViewModel.hasCompletedOnboarding)
    }

    private var devToolsTappedHandler: (() -> Void)? {
        #if DEBUG
        return { showDevTools = true }
        #else
        return nil
        #endif
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

    // MARK: - Expenses Data Management

    private func loadExpensesData() {
        guard let profile = userProfile else { return }

        // Set currency
        let currency = Currency(rawValue: profile.currencyCode) ?? .ron
        expensesViewModel.currency = currency

        // Convert expenses to ExpenseDisplayItem
        expensesViewModel.expenses = expenses.map { expense in
            ExpenseDisplayItem(
                id: expense.id,
                name: expense.name,
                amount: expense.amount,
                frequency: expense.frequency,
                icon: expense.icon,
                categoryId: expense.categoryId,
                linkedAccountId: expense.linkedAccountId,
                isEnabled: expense.isEnabled,
                notes: expense.notes
            )
        }

        // Load custom categories
        let categoryDescriptor = FetchDescriptor<CustomCategory>()
        if let customCategories = try? modelContext.fetch(categoryDescriptor) {
            expensesViewModel.customCategories = customCategories.map { $0.toCategory() }
        }
    }

    private func setupExpensesCallbacks() {
        // Add expense callback
        expensesViewModel.onAddExpense = { [weak modelContext] input in
            guard let context = modelContext else { return }
            let expense = Expense(
                name: input.name,
                amount: input.amount,
                icon: input.icon,
                frequency: input.frequency,
                linkedAccountId: input.linkedAccountId,
                categoryId: input.categoryId,
                notes: input.notes,
                isEnabled: input.isEnabled
            )
            context.insert(expense)
            try? context.save()
        }

        // Update expense callback
        expensesViewModel.onUpdateExpense = { [weak modelContext] input in
            guard let context = modelContext, let id = input.id else { return }
            var descriptor = FetchDescriptor<Expense>(predicate: #Predicate { $0.id == id })
            descriptor.fetchLimit = 1
            guard let expense = try? context.fetch(descriptor).first else { return }
            expense.name = input.name
            expense.amount = input.amount
            expense.frequency = input.frequency
            expense.icon = input.icon
            expense.categoryId = input.categoryId
            expense.linkedAccountId = input.linkedAccountId
            expense.isEnabled = input.isEnabled
            expense.notes = input.notes
            try? context.save()
        }

        // Delete expense callback
        expensesViewModel.onDeleteExpense = { [weak modelContext] id in
            guard let context = modelContext else { return }
            var descriptor = FetchDescriptor<Expense>(predicate: #Predicate { $0.id == id })
            descriptor.fetchLimit = 1
            guard let expense = try? context.fetch(descriptor).first else { return }
            context.delete(expense)
            try? context.save()
        }

        // Toggle expense enabled callback
        expensesViewModel.onToggleExpense = { [weak modelContext] id, enabled in
            guard let context = modelContext else { return }
            var descriptor = FetchDescriptor<Expense>(predicate: #Predicate { $0.id == id })
            descriptor.fetchLimit = 1
            guard let expense = try? context.fetch(descriptor).first else { return }
            expense.isEnabled = enabled
            try? context.save()
        }

        // Add custom category callback
        expensesViewModel.onAddCategory = { [weak modelContext] name, icon, colorHex in
            guard let context = modelContext else { return }
            let category = CustomCategory(name: name, icon: icon, colorHex: colorHex)
            context.insert(category)
            try? context.save()
        }

        // Delete custom category callback
        expensesViewModel.onDeleteCategory = { [weak modelContext] id in
            guard let context = modelContext else { return }
            var descriptor = FetchDescriptor<CustomCategory>(predicate: #Predicate { $0.id == id })
            descriptor.fetchLimit = 1
            guard let category = try? context.fetch(descriptor).first else { return }
            context.delete(category)
            try? context.save()
        }
    }
}

// MARK: - Placeholder Views

private struct InsightsPlaceholder: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                Image(systemName: "lightbulb.max")
                    .iconXxl()
                    .foregroundStyle(DiamerisColors.accentPrimary)

                Text("Insights".localized)
                    .font(.title)
                    .fontWeight(.bold)

                Text("Coming soon".localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Insights".localized)
        }
    }
}

#Preview {
    MainTabView()
}
