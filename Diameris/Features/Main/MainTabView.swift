import SwiftUI
import SwiftData
import os
import DesignSystem
import Dashboard
import Domain
import Persistence
import Utilities
import Expenses

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @Query private var incomes: [Income]
    @Query(sort: \Account.sortOrder) private var accounts: [Account]
    @Query private var expenses: [Expense]
    @Query private var savingsAllocations: [SavingsAllocation]
    @Query private var customCategories: [CustomCategory]

    @State private var dashboardViewModel = DashboardViewModel()
    @State private var expensesViewModel = ExpensesViewModel()
    @State private var dataObserver = DataObserver()
    @State private var showSettings = false

    #if DEBUG
    @State private var showDevTools = false
    #endif

    private var userProfile: UserProfile? { userProfiles.first }

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
            NewMonthSheet(viewModel: dashboardViewModel) { completionData in
                handleNewMonthCompletion(completionData)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
        }
        #if DEBUG
        .sheet(isPresented: $showDevTools) {
            DevDebugView()
        }
        #endif
        .onAppear {
            setupDataObserver()
            refreshAllData()
            setupExpensesCallbacks()
        }
        .onDisappear {
            dataObserver.stopObserving()
        }
    }

    // MARK: - Tab Bar Accessory

    private var newMonthAccessoryButton: some View {
        Button {
            // Catches saves the DataObserver hasn't delivered yet.
            refreshAllData()
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

    // MARK: - Centralized Data Management

    private func setupDataObserver() {
        dataObserver.onDataChanged = { [self] in
            refreshAllData()
        }
        dataObserver.startObserving(modelContext: modelContext)
    }

    private func refreshAllData() {
        loadDashboardData()
        loadExpensesData()
    }

    private func loadDashboardData() {
        guard let profile = userProfile else {
            dashboardViewModel.hasCompletedOnboarding = false
            return
        }
        dashboardViewModel.loadData(from: StoredDashboardData(
            profile: profile,
            monthlyIncome: incomes.first?.amount ?? 0,
            accounts: accounts,
            expenses: expenses,
            allocation: savingsAllocations.first
        ))
        // A stored profile means onboarding finished, even if the name or income is empty.
        dashboardViewModel.hasCompletedOnboarding = true
    }

    // MARK: - Expenses Data Management

    private func loadExpensesData() {
        guard let profile = userProfile else { return }

        expensesViewModel.currency = Currency(rawValue: profile.currencyCode) ?? .ron

        expensesViewModel.applyStoredCategories(customCategories.map { $0.toCategory() })

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

        expensesViewModel.accounts = accounts.map { account in
            ExpenseAccount(
                id: account.id,
                name: account.name,
                accountType: account.accountType,
                isPrimary: account.isPrimary
            )
        }
    }

    /// The view model updates optimistically, so a failed write reloads from the store to drop
    /// the change that was never saved.
    private func setupExpensesCallbacks() {
        let context = modelContext
        @discardableResult
        func write(_ operation: String, _ change: (ModelContext) throws -> Void) -> Bool {
            do {
                try change(context)
                return true
            } catch {
                Logger.persistence.error("\(operation, privacy: .public) failed: \(error)")
                refreshAllData()
                return false
            }
        }

        expensesViewModel.onAddExpense = { input in
            // Store under the view model's id so the optimistic row and the stored row match.
            write("Add expense") { try $0.insertExpense(input.toEntry(id: input.id ?? UUID())) }
        }
        expensesViewModel.onUpdateExpense = { input in
            guard let id = input.id else { return }
            write("Update expense") { try $0.updateExpense(input.toEntry(id: id)) }
        }
        expensesViewModel.onDeleteExpense = { id in
            write("Delete expense") { try $0.deleteExpense(id: id) }
        }
        expensesViewModel.onToggleExpense = { id, enabled in
            write("Toggle expense") { try $0.setExpenseEnabled(id: id, isEnabled: enabled) }
        }
        expensesViewModel.onAddCategory = { [expensesViewModel] id, name, icon, colorHex in
            let saved = write("Add category") {
                try $0.insertCustomCategory(id: id, name: name, icon: icon, colorHex: colorHex)
            }
            if !saved { expensesViewModel.categorySaveFailed(id) }
        }
        expensesViewModel.onDeleteCategory = { id in
            write("Delete category") { try $0.deleteCustomCategory(id: id) }
        }
    }

    // MARK: - New Month Flow Completion

    private func handleNewMonthCompletion(_ data: NewMonthCompletionData) {
        do {
            // DataObserver refreshes the dashboard after the save.
            try modelContext.applyNewMonth(
                income: data.income,
                balances: dashboardViewModel.computeUpdatedBalances(from: data)
            )
            HapticManager.success()
        } catch {
            Logger.persistence.error("Saving new month failed: \(error)")
            HapticManager.error()
        }
    }
}

private extension ExpenseInput {
    func toEntry(id: UUID) -> ExpenseEntry {
        ExpenseEntry(
            id: id,
            name: name,
            amount: amount,
            frequency: frequency,
            icon: icon,
            categoryId: categoryId,
            linkedAccountId: linkedAccountId,
            isEnabled: isEnabled,
            notes: notes
        )
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
