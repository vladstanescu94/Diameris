import Foundation
import SwiftUI
import Domain
import Utilities

public struct ExpenseAccount: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let accountType: AccountType
    public let isPrimary: Bool

    public init(id: UUID, name: String, accountType: AccountType, isPrimary: Bool) {
        self.id = id
        self.name = name
        self.accountType = accountType
        self.isPrimary = isPrimary
    }
}

public struct ExpenseDisplayItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var amount: Decimal
    public var frequency: Frequency
    public var icon: String
    public var categoryId: UUID?
    public var linkedAccountId: UUID?
    public var isEnabled: Bool
    public var notes: String?

    public init(
        id: UUID = UUID(),
        name: String,
        amount: Decimal,
        frequency: Frequency = .monthly,
        icon: String,
        categoryId: UUID? = nil,
        linkedAccountId: UUID? = nil,
        isEnabled: Bool = true,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.frequency = frequency
        self.icon = icon
        self.categoryId = categoryId
        self.linkedAccountId = linkedAccountId
        self.isEnabled = isEnabled
        self.notes = notes
    }

    public init(id: UUID, input: ExpenseInput) {
        self.init(
            id: id,
            name: input.name,
            amount: input.amount,
            frequency: input.frequency,
            icon: input.icon,
            categoryId: input.categoryId,
            linkedAccountId: input.linkedAccountId,
            isEnabled: input.isEnabled,
            notes: input.notes
        )
    }

    public init(from entry: ExpenseEntry) {
        self.id = entry.id
        self.name = entry.name
        self.amount = entry.amount
        self.frequency = entry.frequency
        self.icon = entry.icon
        self.categoryId = entry.categoryId
        self.linkedAccountId = entry.linkedAccountId
        self.isEnabled = entry.isEnabled
        self.notes = entry.notes
    }

    public func toExpenseEntry() -> ExpenseEntry {
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

    public var monthlyAmount: Decimal {
        toExpenseEntry().monthlyAmount
    }

    public var annualAmount: Decimal {
        toExpenseEntry().annualAmount
    }

    public func displayAmount(for viewFrequency: Frequency) -> Decimal {
        toExpenseEntry().displayAmount(for: viewFrequency)
    }
}

public struct ExpenseInput: Sendable {
    public var id: UUID?
    public var name: String
    public var amount: Decimal
    public var frequency: Frequency
    public var icon: String
    public var categoryId: UUID?
    public var linkedAccountId: UUID?
    public var isEnabled: Bool
    public var notes: String?

    public init(
        id: UUID? = nil,
        name: String = "",
        amount: Decimal = 0,
        frequency: Frequency = .monthly,
        icon: String = "dollarsign.circle.fill",
        categoryId: UUID? = nil,
        linkedAccountId: UUID? = nil,
        isEnabled: Bool = true,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.frequency = frequency
        self.icon = icon
        self.categoryId = categoryId
        self.linkedAccountId = linkedAccountId
        self.isEnabled = isEnabled
        self.notes = notes
    }

    public init(from item: ExpenseDisplayItem) {
        self.id = item.id
        self.name = item.name
        self.amount = item.amount
        self.frequency = item.frequency
        self.icon = item.icon
        self.categoryId = item.categoryId
        self.linkedAccountId = item.linkedAccountId
        self.isEnabled = item.isEnabled
        self.notes = item.notes
    }

    public var validationError: ExpenseEntry.ValidationError? {
        ExpenseEntry.validationError(name: name, amount: amount)
    }

    public var isValid: Bool {
        validationError == nil
    }

    public var monthlyAmount: Decimal {
        ExpenseEntry(
            name: name,
            amount: amount,
            frequency: frequency,
            icon: icon
        ).monthlyAmount
    }
}

public struct ExpenseGroup: Identifiable, Equatable, Sendable {
    /// Group ID for expenses without a (known) category.
    public static let uncategorizedId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    public let id: UUID
    public let category: ExpenseCategory?
    public var expenses: [ExpenseDisplayItem]

    public init(category: ExpenseCategory?, expenses: [ExpenseDisplayItem]) {
        self.id = category?.id ?? Self.uncategorizedId
        self.category = category
        self.expenses = expenses
    }

    /// Enabled expenses only.
    public var totalMonthly: Decimal {
        expenses.map { $0.toExpenseEntry() }.totalMonthly
    }

    /// Enabled expenses only.
    public var totalAnnual: Decimal {
        expenses.map { $0.toExpenseEntry() }.totalAnnual
    }

    public var enabledCount: Int {
        expenses.count(where: \.isEnabled)
    }

    public func total(for viewFrequency: Frequency) -> Decimal {
        viewFrequency == .monthly ? totalMonthly : totalAnnual
    }
}

@MainActor
@Observable
public final class ExpensesViewModel {
    // MARK: - Data

    public var expenses: [ExpenseDisplayItem] = []

    public var customCategories: [ExpenseCategory] = []

    /// Local additions the store hasn't reported yet; a refresh keeps only these.
    @ObservationIgnored private var pendingCategoryIds: Set<UUID> = []

    public var currency: Currency = .usd

    public var accounts: [ExpenseAccount] = []

    // MARK: - UI State

    public var selectedFrequencyView: Frequency = .monthly

    public var expandedCategories: Set<UUID> = []

    public var showAddExpense = false

    /// Currently editing expense (nil = adding new)
    public var editingExpense: ExpenseDisplayItem?

    public var showCategoryManagement = false

    public var searchText = ""

    // MARK: - Callbacks (injected by main app)

    public var onAddExpense: ((ExpenseInput) async -> Void)?
    public var onUpdateExpense: ((ExpenseInput) async -> Void)?
    public var onDeleteExpense: ((UUID) async -> Void)?
    public var onToggleExpense: ((UUID, Bool) async -> Void)?
    public var onAddCategory: ((UUID, String, String, String) async -> Void)?
    public var onDeleteCategory: ((UUID) async -> Void)?

    // MARK: - Initialization

    public init() {}

    // MARK: - Category Management

    /// Idempotent: a refresh from persistence may already have delivered the category.
    public func addCategory(id: UUID, name: String, icon: String, colorHex: String) async {
        if !customCategories.contains(where: { $0.id == id }) {
            customCategories.append(.custom(id: id, name: name, icon: icon, colorHex: colorHex))
            pendingCategoryIds.insert(id)
        }
        await onAddCategory?(id, name, icon, colorHex)
    }

    /// Replaces custom categories with the stored ones, keeping local additions the store
    /// hasn't reported yet.
    public func applyStoredCategories(_ stored: [ExpenseCategory]) {
        let storedIds = Set(stored.map(\.id))
        pendingCategoryIds.subtract(storedIds)
        customCategories = stored + customCategories.filter { pendingCategoryIds.contains($0.id) }
    }

    /// Drops an addition the app couldn't persist, so it doesn't linger for the session.
    public func categorySaveFailed(_ id: UUID) {
        pendingCategoryIds.remove(id)
        customCategories.removeAll { $0.id == id }
    }

    /// Removes locally first so the list updates at once; its expenses fall back to Uncategorized.
    public func deleteCategory(_ id: UUID) async {
        pendingCategoryIds.remove(id)
        customCategories.removeAll { $0.id == id }
        await onDeleteCategory?(id)
    }

    // MARK: - Computed Properties

    public var allCategories: [ExpenseCategory] {
        (ExpenseCategory.defaults + customCategories).sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Enabled expenses only.
    public var totalMonthlyExpenses: Decimal {
        expenses.map { $0.toExpenseEntry() }.totalMonthly
    }

    /// Enabled expenses only.
    public var totalAnnualExpenses: Decimal {
        expenses.map { $0.toExpenseEntry() }.totalAnnual
    }

    public var displayTotal: Decimal {
        selectedFrequencyView == .monthly ? totalMonthlyExpenses : totalAnnualExpenses
    }

    /// Uncategorized comes last and also holds expenses whose category no longer exists.
    public var expenseGroups: [ExpenseGroup] {
        let categories = allCategories
        let knownIds = Set(categories.map(\.id))
        let grouped = Dictionary(grouping: filteredExpenses) { expense in
            expense.categoryId.flatMap { knownIds.contains($0) ? $0 : nil }
        }

        var result = categories.compactMap { category in
            grouped[category.id].map { ExpenseGroup(category: category, expenses: $0) }
        }
        if let uncategorized = grouped[nil] {
            result.append(ExpenseGroup(category: nil, expenses: uncategorized))
        }
        return result
    }

    /// Matching is case- and diacritic-insensitive, so "sosea" finds "Șosea".
    public var filteredExpenses: [ExpenseDisplayItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return expenses }
        let categoryNames = Dictionary(
            allCategories.map { ($0.id, $0.name) },
            uniquingKeysWith: { first, _ in first }
        )
        return expenses.filter { expense in
            if expense.name.localizedStandardContains(query) { return true }
            if let categoryId = expense.categoryId,
               let categoryName = categoryNames[categoryId],
               categoryName.localizedStandardContains(query) {
                return true
            }
            if let notes = expense.notes, notes.localizedStandardContains(query) { return true }
            return false
        }
    }

    /// Expanded state for a category group, bindable as `$viewModel[isExpanded: id]`.
    public subscript(isExpanded categoryId: UUID) -> Bool {
        get { expandedCategories.contains(categoryId) }
        set {
            if newValue {
                expandedCategories.insert(categoryId)
            } else {
                expandedCategories.remove(categoryId)
            }
        }
    }

    // MARK: - Actions

    public func toggleCategory(_ categoryId: UUID) {
        self[isExpanded: categoryId].toggle()
    }

    public func expandAll() {
        for group in expenseGroups {
            expandedCategories.insert(group.id)
        }
    }

    public func collapseAll() {
        expandedCategories.removeAll()
    }

    public func startAddingExpense() {
        editingExpense = nil
        showAddExpense = true
    }

    public func startEditingExpense(_ expense: ExpenseDisplayItem) {
        editingExpense = expense
        showAddExpense = true
    }

    public func saveExpense(_ input: ExpenseInput) async {
        if let existingId = input.id {
            if let index = expenses.firstIndex(where: { $0.id == existingId }) {
                expenses[index] = ExpenseDisplayItem(id: existingId, input: input)
            }
            await onUpdateExpense?(input)
        } else {
            // The generated ID goes to persistence so the optimistic row and the stored expense match.
            var newInput = input
            let newId = UUID()
            newInput.id = newId
            expenses.append(ExpenseDisplayItem(id: newId, input: newInput))
            await onAddExpense?(newInput)
        }
        showAddExpense = false
        editingExpense = nil
    }

    public func deleteExpense(_ id: UUID) async {
        expenses.removeAll { $0.id == id }
        await onDeleteExpense?(id)
    }

    public func toggleExpenseEnabled(_ expense: ExpenseDisplayItem) async {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index].isEnabled = !expense.isEnabled
        }
        await onToggleExpense?(expense.id, !expense.isEnabled)
    }
}
