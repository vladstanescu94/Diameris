import Foundation
import Testing
@testable import Expenses
import Domain

/// Tests for ExpensesViewModel
@Suite("ExpensesViewModel Tests")
struct ExpensesViewModelTests {

    // MARK: - Initial State

    @Suite("Initial State")
    struct InitialStateTests {

        @Test("ViewModel starts with empty expenses")
        @MainActor
        func emptyExpenses() {
            let viewModel = ExpensesViewModel()
            #expect(viewModel.expenses.isEmpty)
        }

        @Test("ViewModel starts with default categories")
        @MainActor
        func defaultCategories() {
            let viewModel = ExpensesViewModel()
            #expect(viewModel.categories.count == Category.defaults.count)
        }

        @Test("ViewModel starts with monthly view")
        @MainActor
        func monthlyView() {
            let viewModel = ExpensesViewModel()
            #expect(viewModel.selectedFrequencyView == .monthly)
        }

        @Test("ViewModel starts with no expanded categories")
        @MainActor
        func noExpandedCategories() {
            let viewModel = ExpensesViewModel()
            #expect(viewModel.expandedCategories.isEmpty)
        }
    }

    // MARK: - Expense Totals

    @Suite("Expense Totals")
    struct TotalTests {

        @Test("Total monthly is zero when no expenses")
        @MainActor
        func totalMonthlyZero() {
            let viewModel = ExpensesViewModel()
            #expect(viewModel.totalMonthlyExpenses == 0)
        }

        @Test("Total monthly calculates from monthly expenses")
        @MainActor
        func totalMonthlyFromMonthly() {
            let viewModel = ExpensesViewModel()
            viewModel.expenses = [
                ExpenseDisplayItem(name: "Expense 1", amount: 100, frequency: .monthly, icon: "star"),
                ExpenseDisplayItem(name: "Expense 2", amount: 200, frequency: .monthly, icon: "star")
            ]
            #expect(viewModel.totalMonthlyExpenses == 300)
        }

        @Test("Total monthly calculates from annual expenses")
        @MainActor
        func totalMonthlyFromAnnual() {
            let viewModel = ExpensesViewModel()
            viewModel.expenses = [
                ExpenseDisplayItem(name: "Annual", amount: 1200, frequency: .annual, icon: "star")
            ]
            // Using approximate comparison due to Decimal division precision
            #expect(abs(viewModel.totalMonthlyExpenses - 100) < Decimal(string: "0.01")!)
        }

        @Test("Total excludes disabled expenses")
        @MainActor
        func totalExcludesDisabled() {
            let viewModel = ExpensesViewModel()
            viewModel.expenses = [
                ExpenseDisplayItem(name: "Enabled", amount: 100, frequency: .monthly, icon: "star", isEnabled: true),
                ExpenseDisplayItem(name: "Disabled", amount: 200, frequency: .monthly, icon: "star", isEnabled: false)
            ]
            #expect(viewModel.totalMonthlyExpenses == 100)
        }
    }

    // MARK: - Expense Groups

    @Suite("Expense Groups")
    struct GroupTests {

        @Test("Groups expenses by category")
        @MainActor
        func groupsByCategory() {
            let viewModel = ExpensesViewModel()
            viewModel.expenses = [
                ExpenseDisplayItem(name: "Gas", amount: 100, icon: "car", categoryId: Category.autoTransport.id),
                ExpenseDisplayItem(name: "Insurance", amount: 200, icon: "shield", categoryId: Category.autoTransport.id),
                ExpenseDisplayItem(name: "Netflix", amount: 15, icon: "tv", categoryId: Category.subscriptions.id)
            ]

            let groups = viewModel.expenseGroups
            #expect(groups.count == 2)

            let autoGroup = groups.first { $0.category?.id == Category.autoTransport.id }
            #expect(autoGroup?.expenses.count == 2)
        }

        @Test("Uncategorized expenses are grouped together")
        @MainActor
        func uncategorizedGroup() {
            let viewModel = ExpensesViewModel()
            viewModel.expenses = [
                ExpenseDisplayItem(name: "Random 1", amount: 50, icon: "star"),
                ExpenseDisplayItem(name: "Random 2", amount: 75, icon: "star")
            ]

            let groups = viewModel.expenseGroups
            #expect(groups.count == 1)
            #expect(groups.first?.category == nil)
            #expect(groups.first?.expenses.count == 2)
        }
    }

    // MARK: - Category Toggle

    @Suite("Category Toggle")
    struct CategoryToggleTests {

        @Test("Toggle expands collapsed category")
        @MainActor
        func expandsCategory() {
            let viewModel = ExpensesViewModel()
            let categoryId = Category.autoTransport.id

            viewModel.toggleCategory(categoryId)

            #expect(viewModel.expandedCategories.contains(categoryId))
        }

        @Test("Toggle collapses expanded category")
        @MainActor
        func collapsesCategory() {
            let viewModel = ExpensesViewModel()
            let categoryId = Category.autoTransport.id

            viewModel.expandedCategories.insert(categoryId)
            viewModel.toggleCategory(categoryId)

            #expect(!viewModel.expandedCategories.contains(categoryId))
        }

        @Test("Expand all expands all groups")
        @MainActor
        func expandAll() {
            let viewModel = ExpensesViewModel()
            viewModel.expenses = [
                ExpenseDisplayItem(name: "Gas", amount: 100, icon: "car", categoryId: Category.autoTransport.id),
                ExpenseDisplayItem(name: "Netflix", amount: 15, icon: "tv", categoryId: Category.subscriptions.id)
            ]

            viewModel.expandAll()

            #expect(viewModel.expandedCategories.count == 2)
        }

        @Test("Collapse all clears all expanded")
        @MainActor
        func collapseAll() {
            let viewModel = ExpensesViewModel()
            viewModel.expandedCategories = [Category.autoTransport.id, Category.subscriptions.id]

            viewModel.collapseAll()

            #expect(viewModel.expandedCategories.isEmpty)
        }
    }

    // MARK: - Search Filter

    @Suite("Search Filter")
    struct SearchTests {

        @Test("Empty search returns all expenses")
        @MainActor
        func emptySearchReturnsAll() {
            let viewModel = ExpensesViewModel()
            viewModel.expenses = [
                ExpenseDisplayItem(name: "Gas", amount: 100, icon: "car"),
                ExpenseDisplayItem(name: "Food", amount: 200, icon: "cart")
            ]

            #expect(viewModel.filteredExpenses.count == 2)
        }

        @Test("Search filters by name")
        @MainActor
        func filtersByName() {
            let viewModel = ExpensesViewModel()
            viewModel.expenses = [
                ExpenseDisplayItem(name: "Gas", amount: 100, icon: "car"),
                ExpenseDisplayItem(name: "Food", amount: 200, icon: "cart")
            ]
            viewModel.searchText = "gas"

            #expect(viewModel.filteredExpenses.count == 1)
            #expect(viewModel.filteredExpenses.first?.name == "Gas")
        }

        @Test("Search is case insensitive")
        @MainActor
        func caseInsensitive() {
            let viewModel = ExpensesViewModel()
            viewModel.expenses = [
                ExpenseDisplayItem(name: "Gas", amount: 100, icon: "car")
            ]
            viewModel.searchText = "GAS"

            #expect(viewModel.filteredExpenses.count == 1)
        }
    }

    // MARK: - ExpenseDisplayItem

    @Suite("ExpenseDisplayItem")
    struct DisplayItemTests {

        @Test("Monthly amount same for monthly frequency")
        func monthlyAmountMonthly() {
            let item = ExpenseDisplayItem(name: "Test", amount: 100, frequency: .monthly, icon: "star")
            #expect(item.monthlyAmount == 100)
        }

        @Test("Monthly amount divided for annual frequency")
        func monthlyAmountAnnual() {
            let item = ExpenseDisplayItem(name: "Test", amount: 1200, frequency: .annual, icon: "star")
            #expect(abs(item.monthlyAmount - 100) < Decimal(string: "0.01")!)
        }

        @Test("Creates from ExpenseEntry")
        func createsFromEntry() {
            let entry = ExpenseEntry(
                name: "Test",
                amount: 100,
                frequency: .monthly,
                icon: "star",
                categoryId: Category.autoTransport.id
            )

            let item = ExpenseDisplayItem(from: entry)

            #expect(item.name == "Test")
            #expect(item.amount == 100)
            #expect(item.frequency == .monthly)
            #expect(item.categoryId == Category.autoTransport.id)
        }
    }

    // MARK: - ExpenseInput

    @Suite("ExpenseInput")
    struct InputTests {

        @Test("Empty name is invalid")
        func emptyNameInvalid() {
            let input = ExpenseInput(name: "", amount: 100, icon: "star")
            #expect(!input.isValid)
        }

        @Test("Whitespace only name is invalid")
        func whitespaceNameInvalid() {
            let input = ExpenseInput(name: "   ", amount: 100, icon: "star")
            #expect(!input.isValid)
        }

        @Test("Zero amount is invalid")
        func zeroAmountInvalid() {
            let input = ExpenseInput(name: "Test", amount: 0, icon: "star")
            #expect(!input.isValid)
        }

        @Test("Valid name and amount is valid")
        func validInput() {
            let input = ExpenseInput(name: "Test", amount: 100, icon: "star")
            #expect(input.isValid)
        }

        @Test("Creates from display item")
        func createsFromDisplayItem() {
            let item = ExpenseDisplayItem(
                id: UUID(),
                name: "Test",
                amount: 100,
                frequency: .annual,
                icon: "star",
                categoryId: Category.autoTransport.id
            )

            let input = ExpenseInput(from: item)

            #expect(input.id == item.id)
            #expect(input.name == "Test")
            #expect(input.frequency == .annual)
        }
    }
}
