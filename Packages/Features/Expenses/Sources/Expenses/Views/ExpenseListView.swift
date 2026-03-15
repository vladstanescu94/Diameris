import SwiftUI
import Domain
import DesignSystem
import Utilities
/// Main view for the Expenses tab
public struct ExpenseListView: View {
    @Bindable var viewModel: ExpensesViewModel

    public init(viewModel: ExpensesViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    // Summary header
                    summaryHeader

                    // Frequency toggle
                    frequencyToggle

                    // Category groups
                    if viewModel.expenseGroups.isEmpty {
                        emptyState
                    } else {
                        categoryList
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Expenses".localized)
            .searchable(text: $viewModel.searchText, prompt: "Search expenses".localized)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Expense".localized, systemImage: "plus") {
                        HapticManager.lightTap()
                        viewModel.startAddingExpense()
                    }
                }

                ToolbarItem(placement: .secondaryAction) {
                    Menu("Options".localized, systemImage: "ellipsis.circle") {
                        Button {
                            HapticManager.lightTap()
                            withAnimation(SpringPreset.responsive) {
                                viewModel.expandAll()
                            }
                        } label: {
                            Label("Expand All".localized, systemImage: "rectangle.expand.vertical")
                        }

                        Button {
                            HapticManager.lightTap()
                            withAnimation(SpringPreset.responsive) {
                                viewModel.collapseAll()
                            }
                        } label: {
                            Label("Collapse All".localized, systemImage: "rectangle.compress.vertical")
                        }

                        Divider()

                        Button {
                            HapticManager.lightTap()
                            viewModel.showCategoryManagement = true
                        } label: {
                            Label("Manage Categories".localized, systemImage: "folder.badge.gearshape")
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showAddExpense) {
                AddExpenseSheet(
                    viewModel: viewModel,
                    editingExpense: viewModel.editingExpense
                )
            }
            .sheet(isPresented: $viewModel.showCategoryManagement) {
                CategoryManagementView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        VStack(spacing: Spacing.sm) {
            Text("Total \(viewModel.selectedFrequencyView.displayName) Expenses".localized)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(AmountFormatter.formatForDisplay(viewModel.displayTotal, currency: viewModel.currency.rawValue))
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(SpringPreset.smooth, value: viewModel.displayTotal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .glassCard()
    }

    // MARK: - Frequency Toggle

    private var frequencyToggle: some View {
        FrequencyPicker(selection: $viewModel.selectedFrequencyView)
    }

    // MARK: - Category List

    private var categoryList: some View {
        LazyVStack(spacing: Spacing.md) {
            ForEach(viewModel.expenseGroups) { group in
                ExpenseCategoryCard(
                    group: group,
                    displayFrequency: viewModel.selectedFrequencyView,
                    currency: viewModel.currency.rawValue,
                    isExpanded: Binding(
                        get: { viewModel.expandedCategories.contains(group.id) },
                        set: { expanded in
                            if expanded {
                                viewModel.expandedCategories.insert(group.id)
                            } else {
                                viewModel.expandedCategories.remove(group.id)
                            }
                        }
                    ),
                    onExpenseTap: { expense in
                        viewModel.startEditingExpense(expense)
                    },
                    onExpenseToggle: { expense, enabled in
                        Task {
                            await viewModel.toggleExpenseEnabled(expense)
                        }
                    },
                    onExpenseDelete: { expense in
                        Task {
                            await viewModel.deleteExpense(expense.id)
                        }
                    }
                )
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Expenses Yet".localized, systemImage: "list.bullet.rectangle")
        } description: {
            Text("Add your first expense to start tracking your budget.".localized)
        } actions: {
            Button("Add Expense".localized, systemImage: "plus") {
                HapticManager.mediumTap()
                viewModel.startAddingExpense()
            }
            .buttonStyle(.glassProminent)
        }
        .padding(.vertical, Spacing.xxl)
    }
}

#Preview {
    ExpenseListView(viewModel: {
        let vm = ExpensesViewModel()
        vm.expenses = [
            ExpenseDisplayItem(
                name: "Gas",
                amount: 300,
                frequency: .monthly,
                icon: "car.fill",
                categoryId: ExpenseCategory.autoTransport.id
            ),
            ExpenseDisplayItem(
                name: "Netflix",
                amount: 15.99,
                frequency: .monthly,
                icon: "tv.fill",
                categoryId: ExpenseCategory.subscriptions.id
            ),
            ExpenseDisplayItem(
                name: "Car Insurance",
                amount: 2400,
                frequency: .annual,
                icon: "shield.fill",
                categoryId: ExpenseCategory.autoTransport.id
            )
        ]
        vm.expandedCategories = [ExpenseCategory.autoTransport.id]
        return vm
    }())
}
