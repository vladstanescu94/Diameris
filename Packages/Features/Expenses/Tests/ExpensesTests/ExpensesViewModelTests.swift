import Foundation
import Testing
@testable import Expenses
import Domain

/// Per-expense frequency conversion is covered by Domain's `ExpenseEntryTests`; these tests
/// cover totals, grouping, search and the persistence-callback contract.
@MainActor
struct ExpensesViewModelTests {

    // MARK: - Totals

    /// Gas 300/month, Insurance 2400/year, Gym 100/month (disabled).
    private func makeViewModel() -> ExpensesViewModel {
        let viewModel = ExpensesViewModel()
        viewModel.expenses = [
            ExpenseDisplayItem(name: "Gas", amount: 300, icon: "car.fill", categoryId: Category.autoTransport.id),
            ExpenseDisplayItem(
                name: "Insurance",
                amount: 2400,
                frequency: .annual,
                icon: "shield.fill",
                categoryId: Category.autoTransport.id
            ),
            ExpenseDisplayItem(name: "Gym", amount: 100, icon: "dumbbell.fill", isEnabled: false)
        ]
        return viewModel
    }

    @Test(arguments: [(Frequency.monthly, Decimal(500)), (.annual, Decimal(6000))])
    func `Totals include annual expenses and skip disabled ones`(view: Frequency, expected: Decimal) throws {
        let viewModel = makeViewModel()
        viewModel.selectedFrequencyView = view

        #expect(viewModel.displayTotal == expected)

        let auto = try #require(viewModel.expenseGroups.first { $0.category == .autoTransport })
        #expect(auto.total(for: view) == expected, "Only the disabled Gym expense is outside Auto")
        #expect(auto.enabledCount == 2)
    }

    // MARK: - CRUD via Callbacks

    @Test func `Adding an expense updates totals and persists it under the same ID`() async throws {
        let viewModel = makeViewModel()
        let recorder = CallbackRecorder(viewModel)
        viewModel.startAddingExpense()

        await viewModel.saveExpense(ExpenseInput(name: "Netflix", amount: 60, icon: "tv.fill"))

        let persisted = try #require(recorder.added.first)
        let local = try #require(viewModel.expenses.first { $0.name == "Netflix" })
        #expect(persisted.id == local.id, "Optimistic row and stored expense must share an identity")
        #expect(viewModel.totalMonthlyExpenses == 560)
        #expect(viewModel.showAddExpense == false)
        #expect(viewModel.editingExpense == nil)
    }

    @Test func `Editing an expense updates totals and persists the change`() async throws {
        let viewModel = makeViewModel()
        let recorder = CallbackRecorder(viewModel)
        let insurance = try #require(viewModel.expenses.first { $0.name == "Insurance" })
        viewModel.startEditingExpense(insurance)
        #expect(viewModel.editingExpense == insurance)

        var input = ExpenseInput(from: insurance)
        input.frequency = .monthly
        await viewModel.saveExpense(input)

        #expect(recorder.updated.map(\.id) == [insurance.id])
        #expect(viewModel.expenses.count == 3)
        #expect(viewModel.totalMonthlyExpenses == 2700, "300 + 2400 now billed monthly")
    }

    @Test func `Deleting an expense updates totals and persists the deletion`() async throws {
        let viewModel = makeViewModel()
        let recorder = CallbackRecorder(viewModel)
        let gas = try #require(viewModel.expenses.first { $0.name == "Gas" })

        await viewModel.deleteExpense(gas.id)

        #expect(recorder.deleted == [gas.id])
        #expect(viewModel.expenses.contains { $0.id == gas.id } == false)
        #expect(viewModel.totalMonthlyExpenses == 200)
    }

    @Test func `Toggling an expense updates totals and persists the new state`() async throws {
        let viewModel = makeViewModel()
        let recorder = CallbackRecorder(viewModel)
        let gym = try #require(viewModel.expenses.first { $0.name == "Gym" })

        await viewModel.toggleExpenseEnabled(gym)

        #expect(recorder.toggled.count == 1)
        #expect(recorder.toggled.first?.id == gym.id)
        #expect(recorder.toggled.first?.enabled == true)
        #expect(viewModel.totalMonthlyExpenses == 600)
    }

    // MARK: - Search

    @Test(arguments: [
        ("", ["Gas", "Taxă \u{0219}osea", "Între\u{0163}inere", "Insurance"]),
        ("  gas ", ["Gas"]),                             // Surrounding whitespace ignored
        ("sosea", ["Taxă \u{0219}osea"]),                // Diacritic-insensitive (ș)
        ("\u{015F}osea", ["Taxă \u{0219}osea"]),         // Cedilla ş finds comma-below ș
        ("intre\u{021B}inere", ["Între\u{0163}inere"]),  // Comma-below ț finds cedilla ţ
        ("AUTO", ["Gas", "Insurance"]),                  // Default category name
        ("casă", ["Între\u{0163}inere"]),                // Custom category name, "casa"/"Casă"
        ("partner", ["Insurance"]),                      // Notes
        ("xyz", [])
    ])
    func `Search matches name, category and notes ignoring case and diacritics`(query: String, expected: [String]) {
        let home = Category.custom(name: "Casă", icon: "house.fill", colorHex: "#10B981")
        let viewModel = ExpensesViewModel()
        viewModel.customCategories = [home]
        viewModel.expenses = [
            ExpenseDisplayItem(name: "Gas", amount: 300, icon: "car.fill", categoryId: Category.autoTransport.id),
            ExpenseDisplayItem(name: "Taxă \u{0219}osea", amount: 20, icon: "road.lanes"),
            ExpenseDisplayItem(name: "Între\u{0163}inere", amount: 400, icon: "house.fill", categoryId: home.id),
            ExpenseDisplayItem(
                name: "Insurance",
                amount: 2400,
                frequency: .annual,
                icon: "shield.fill",
                categoryId: Category.autoTransport.id,
                notes: "Shared with partner"
            )
        ]

        viewModel.searchText = query

        #expect(viewModel.filteredExpenses.map(\.name) == expected)
    }

    // MARK: - Grouping

    @Test func `Groups follow category order with Uncategorized last`() {
        let viewModel = ExpensesViewModel()
        viewModel.expenses = [
            ExpenseDisplayItem(name: "Loose", amount: 10, icon: "circle"),
            ExpenseDisplayItem(name: "Netflix", amount: 60, icon: "tv.fill", categoryId: Category.subscriptions.id),
            ExpenseDisplayItem(name: "Gas", amount: 300, icon: "car.fill", categoryId: Category.autoTransport.id)
        ]

        let groups = viewModel.expenseGroups

        #expect(groups.map(\.category) == [.autoTransport, .subscriptions, nil])
        #expect(groups.last?.id == ExpenseGroup.uncategorizedId)
    }

    @Test func `Expanded state is bindable per group and resettable`() {
        let viewModel = makeViewModel()
        let autoId = Category.autoTransport.id

        viewModel[isExpanded: autoId] = true
        #expect(viewModel.expandedCategories == [autoId])
        viewModel.toggleCategory(autoId)
        #expect(viewModel.expandedCategories.isEmpty)

        viewModel.expandAll()
        #expect(viewModel.expandedCategories == Set(viewModel.expenseGroups.map(\.id)))
        viewModel.collapseAll()
        #expect(viewModel.expandedCategories.isEmpty)
    }

    // MARK: - Custom Categories

    @Test func `Custom category lifecycle: add, group, delete falls back to Uncategorized`() async throws {
        let viewModel = ExpensesViewModel()
        let recorder = CallbackRecorder(viewModel)
        let categoryId = UUID()

        await viewModel.addCategory(id: categoryId, name: "Pets", icon: "pawprint.fill", colorHex: "#F59E0B")
        // A persistence refresh can deliver the category before the sheet's add completes.
        await viewModel.addCategory(id: categoryId, name: "Pets", icon: "pawprint.fill", colorHex: "#F59E0B")

        #expect(viewModel.customCategories.map(\.id) == [categoryId], "No duplicate on repeated add")
        #expect(viewModel.allCategories.last?.id == categoryId, "Custom categories sort after defaults")
        #expect(recorder.addedCategories.count == 2)

        viewModel.expenses = [
            ExpenseDisplayItem(name: "Cat food", amount: 400, icon: "pawprint.fill", categoryId: categoryId),
            ExpenseDisplayItem(name: "Loose", amount: 10, icon: "circle")
        ]
        #expect(viewModel.expenseGroups.map(\.id) == [categoryId, ExpenseGroup.uncategorizedId])

        await viewModel.deleteCategory(categoryId)

        #expect(recorder.deletedCategories == [categoryId])
        #expect(viewModel.customCategories.isEmpty)
        let groups = viewModel.expenseGroups
        #expect(groups.map(\.id) == [ExpenseGroup.uncategorizedId], "Orphaned expenses join the single Uncategorized group")
        #expect(groups.first?.expenses.map(\.name) == ["Cat food", "Loose"])
    }

    @Test func `A category that failed to save disappears and stays gone`() async {
        let viewModel = ExpensesViewModel()
        let categoryId = UUID()
        await viewModel.addCategory(id: categoryId, name: "Pets", icon: "pawprint.fill", colorHex: "#F59E0B")

        viewModel.applyStoredCategories([])
        #expect(viewModel.customCategories.map(\.id) == [categoryId], "A pending addition survives a refresh")

        viewModel.categorySaveFailed(categoryId)
        viewModel.applyStoredCategories([])
        #expect(viewModel.customCategories.isEmpty)
    }

    // MARK: - Input Validation

    @Test(arguments: [
        ("Rent", Decimal(0), nil),
        ("   ", Decimal(100), .nameMissing),
        (String(repeating: "a", count: 101), Decimal(100), .nameTooLong),
        ("Rent", Decimal(-1), .amountNegative),
        ("Rent", Decimal(10_000_001), .amountTooHigh)
    ] as [(String, Decimal, ExpenseEntry.ValidationError?)])
    func `Input validation follows the Domain rules`(
        name: String, amount: Decimal, error: ExpenseEntry.ValidationError?
    ) {
        let input = ExpenseInput(name: name, amount: amount)
        #expect(input.validationError == error)
        #expect(input.isValid == (error == nil))
    }
}

// MARK: - Callback Recorder

@MainActor
private final class CallbackRecorder {
    var added: [ExpenseInput] = []
    var updated: [ExpenseInput] = []
    var deleted: [UUID] = []
    var toggled: [(id: UUID, enabled: Bool)] = []
    var addedCategories: [UUID] = []
    var deletedCategories: [UUID] = []

    init(_ viewModel: ExpensesViewModel) {
        viewModel.onAddExpense = { self.added.append($0) }
        viewModel.onUpdateExpense = { self.updated.append($0) }
        viewModel.onDeleteExpense = { self.deleted.append($0) }
        viewModel.onToggleExpense = { self.toggled.append((id: $0, enabled: $1)) }
        viewModel.onAddCategory = { id, _, _, _ in self.addedCategories.append(id) }
        viewModel.onDeleteCategory = { self.deletedCategories.append($0) }
    }
}
