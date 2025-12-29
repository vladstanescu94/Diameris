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

    // MARK: - All Categories

    @Suite("All Categories")
    @MainActor
    struct AllCategoriesTests {

        @Test("All categories includes defaults")
        func includesDefaults() {
            let viewModel = ExpensesViewModel()
            #expect(viewModel.allCategories.count >= ExpenseCategory.defaults.count)
        }

        @Test("All categories includes custom categories")
        func includesCustom() {
            let viewModel = ExpensesViewModel()
            let customCategory = ExpenseCategory.custom(
                id: UUID(),
                name: "Custom",
                icon: "star",
                colorHex: "#FF0000",
                sortOrder: 100
            )
            viewModel.customCategories = [customCategory]

            #expect(viewModel.allCategories.contains { $0.name == "Custom" })
        }

        @Test("All categories sorted by sort order")
        func sortedBySortOrder() {
            let viewModel = ExpensesViewModel()

            let categories = viewModel.allCategories
            for i in 0..<(categories.count - 1) {
                #expect(categories[i].sortOrder <= categories[i + 1].sortOrder)
            }
        }
    }

    // MARK: - Display Total

    @Suite("Display Total")
    @MainActor
    struct DisplayTotalTests {

        @Test("Display total shows monthly when monthly selected")
        func showsMonthlyTotal() {
            let viewModel = ExpensesViewModel()
            viewModel.selectedFrequencyView = .monthly
            viewModel.expenses = [
                ExpenseDisplayItem(name: "Test", amount: 100, frequency: .monthly, icon: "star")
            ]

            #expect(viewModel.displayTotal == 100)
        }

        @Test("Display total shows annual when annual selected")
        func showsAnnualTotal() {
            let viewModel = ExpensesViewModel()
            viewModel.selectedFrequencyView = .annual
            viewModel.expenses = [
                ExpenseDisplayItem(name: "Test", amount: 100, frequency: .monthly, icon: "star")
            ]

            #expect(viewModel.displayTotal == 1200)
        }
    }

    // MARK: - Annual Totals

    @Suite("Annual Totals")
    @MainActor
    struct AnnualTotalTests {

        @Test("Total annual multiplies monthly expenses by 12")
        func annualFromMonthly() {
            let viewModel = ExpensesViewModel()
            viewModel.expenses = [
                ExpenseDisplayItem(name: "Test", amount: 100, frequency: .monthly, icon: "star")
            ]

            #expect(viewModel.totalAnnualExpenses == 1200)
        }

        @Test("Total annual keeps annual expenses as-is")
        func annualFromAnnual() {
            let viewModel = ExpensesViewModel()
            viewModel.expenses = [
                ExpenseDisplayItem(name: "Test", amount: 1200, frequency: .annual, icon: "star")
            ]

            #expect(viewModel.totalAnnualExpenses == 1200)
        }

        @Test("Total annual excludes disabled expenses")
        func excludesDisabled() {
            let viewModel = ExpensesViewModel()
            viewModel.expenses = [
                ExpenseDisplayItem(name: "Enabled", amount: 100, frequency: .monthly, icon: "star", isEnabled: true),
                ExpenseDisplayItem(name: "Disabled", amount: 200, frequency: .monthly, icon: "star", isEnabled: false)
            ]

            #expect(viewModel.totalAnnualExpenses == 1200)
        }
    }

    // MARK: - Search by Category and Notes

    @Suite("Advanced Search")
    @MainActor
    struct AdvancedSearchTests {

        @Test("Search filters by category name")
        func filtersByCategoryName() {
            let viewModel = ExpensesViewModel()
            viewModel.expenses = [
                ExpenseDisplayItem(name: "Gas", amount: 100, icon: "car", categoryId: Category.autoTransport.id),
                ExpenseDisplayItem(name: "Food", amount: 200, icon: "cart", categoryId: Category.lifestyle.id)
            ]
            viewModel.searchText = "auto"

            #expect(viewModel.filteredExpenses.count == 1)
            #expect(viewModel.filteredExpenses.first?.name == "Gas")
        }

        @Test("Search filters by custom category name")
        func filtersByCustomCategoryName() {
            let viewModel = ExpensesViewModel()
            let customId = UUID()
            viewModel.customCategories = [
                ExpenseCategory.custom(id: customId, name: "My Custom", icon: "star", colorHex: "#FF0000", sortOrder: 100)
            ]
            viewModel.expenses = [
                ExpenseDisplayItem(name: "Linked Expense", amount: 100, icon: "star", categoryId: customId),
                ExpenseDisplayItem(name: "Another Linked", amount: 150, icon: "star", categoryId: customId),
                ExpenseDisplayItem(name: "Other", amount: 200, icon: "cart")
            ]
            viewModel.searchText = "my custom" // Search by custom category name

            #expect(viewModel.filteredExpenses.count == 2) // Both expenses linked to "My Custom" category
        }

        @Test("Search filters by notes")
        func filtersByNotes() {
            let viewModel = ExpensesViewModel()
            viewModel.expenses = [
                ExpenseDisplayItem(name: "Gas", amount: 100, icon: "car", notes: "Monthly fuel budget"),
                ExpenseDisplayItem(name: "Food", amount: 200, icon: "cart", notes: "Groceries only")
            ]
            viewModel.searchText = "fuel"

            #expect(viewModel.filteredExpenses.count == 1)
            #expect(viewModel.filteredExpenses.first?.name == "Gas")
        }
    }

    // MARK: - CRUD Operations

    @Suite("CRUD Operations")
    @MainActor
    struct CRUDTests {

        @Test("Save expense adds new expense")
        func saveAddsNew() async {
            let viewModel = ExpensesViewModel()
            let input = ExpenseInput(name: "New Expense", amount: 100, icon: "star")

            await viewModel.saveExpense(input)

            #expect(viewModel.expenses.count == 1)
            #expect(viewModel.expenses.first?.name == "New Expense")
        }

        @Test("Save expense updates existing expense")
        func saveUpdatesExisting() async {
            let viewModel = ExpensesViewModel()
            let existingId = UUID()
            viewModel.expenses = [
                ExpenseDisplayItem(id: existingId, name: "Old Name", amount: 100, icon: "star")
            ]

            var input = ExpenseInput(name: "New Name", amount: 200, icon: "heart")
            input.id = existingId

            await viewModel.saveExpense(input)

            #expect(viewModel.expenses.count == 1)
            #expect(viewModel.expenses.first?.name == "New Name")
            #expect(viewModel.expenses.first?.amount == 200)
        }

        @Test("Save expense closes add sheet")
        func saveClosesSheet() async {
            let viewModel = ExpensesViewModel()
            viewModel.showAddExpense = true

            await viewModel.saveExpense(ExpenseInput(name: "Test", amount: 100, icon: "star"))

            #expect(viewModel.showAddExpense == false)
        }

        @Test("Delete expense removes from list")
        func deleteRemovesExpense() async {
            let viewModel = ExpensesViewModel()
            let expenseId = UUID()
            viewModel.expenses = [
                ExpenseDisplayItem(id: expenseId, name: "To Delete", amount: 100, icon: "star")
            ]

            await viewModel.deleteExpense(expenseId)

            #expect(viewModel.expenses.isEmpty)
        }

        @Test("Toggle expense enabled flips state")
        func toggleFlipsEnabled() async {
            let viewModel = ExpensesViewModel()
            let expense = ExpenseDisplayItem(name: "Test", amount: 100, icon: "star", isEnabled: true)
            viewModel.expenses = [expense]

            await viewModel.toggleExpenseEnabled(expense)

            #expect(viewModel.expenses.first?.isEnabled == false)
        }
    }

    // MARK: - UI State

    @Suite("UI State")
    @MainActor
    struct UIStateTests {

        @Test("Start adding expense shows sheet and clears editing")
        func startAddingExpense() {
            let viewModel = ExpensesViewModel()
            viewModel.editingExpense = ExpenseDisplayItem(name: "Old", amount: 100, icon: "star")

            viewModel.startAddingExpense()

            #expect(viewModel.showAddExpense == true)
            #expect(viewModel.editingExpense == nil)
        }

        @Test("Start editing expense shows sheet and sets editing")
        func startEditingExpense() {
            let viewModel = ExpensesViewModel()
            let expense = ExpenseDisplayItem(name: "Test", amount: 100, icon: "star")

            viewModel.startEditingExpense(expense)

            #expect(viewModel.showAddExpense == true)
            #expect(viewModel.editingExpense?.name == "Test")
        }
    }

    // MARK: - ExpenseGroup

    @Suite("ExpenseGroup")
    struct ExpenseGroupTests {

        @Test("Total monthly sums enabled expenses")
        func totalMonthlySumsEnabled() {
            let group = ExpenseGroup(
                category: Category.autoTransport,
                expenses: [
                    ExpenseDisplayItem(name: "Gas", amount: 100, frequency: .monthly, icon: "car", isEnabled: true),
                    ExpenseDisplayItem(name: "Insurance", amount: 200, frequency: .monthly, icon: "shield", isEnabled: true),
                    ExpenseDisplayItem(name: "Disabled", amount: 500, frequency: .monthly, icon: "x", isEnabled: false)
                ]
            )

            #expect(group.totalMonthly == 300)
        }

        @Test("Total annual multiplies monthly by 12")
        func totalAnnualMultiplies() {
            let group = ExpenseGroup(
                category: Category.autoTransport,
                expenses: [
                    ExpenseDisplayItem(name: "Gas", amount: 100, frequency: .monthly, icon: "car", isEnabled: true)
                ]
            )

            #expect(group.totalAnnual == 1200)
        }

        @Test("Enabled count excludes disabled")
        func enabledCountExcludesDisabled() {
            let group = ExpenseGroup(
                category: Category.autoTransport,
                expenses: [
                    ExpenseDisplayItem(name: "Enabled 1", amount: 100, icon: "car", isEnabled: true),
                    ExpenseDisplayItem(name: "Enabled 2", amount: 200, icon: "car", isEnabled: true),
                    ExpenseDisplayItem(name: "Disabled", amount: 500, icon: "x", isEnabled: false)
                ]
            )

            #expect(group.enabledCount == 2)
        }
    }

    // MARK: - Custom Categories

    @Suite("Custom Categories")
    @MainActor
    struct CustomCategoriesTests {

        @Test("Add category adds to local state")
        func addCategoryAddsLocal() async {
            let viewModel = ExpensesViewModel()
            let categoryId = UUID()

            await viewModel.addCategory(id: categoryId, name: "Custom", icon: "star", colorHex: "#FF0000")

            #expect(viewModel.customCategories.count == 1)
            #expect(viewModel.customCategories.first?.name == "Custom")
        }

        @Test("Custom categories appear in all categories")
        func customInAllCategories() async {
            let viewModel = ExpensesViewModel()
            let categoryId = UUID()

            await viewModel.addCategory(id: categoryId, name: "Custom", icon: "star", colorHex: "#FF0000")

            #expect(viewModel.allCategories.contains { $0.id == categoryId })
        }
    }
}
