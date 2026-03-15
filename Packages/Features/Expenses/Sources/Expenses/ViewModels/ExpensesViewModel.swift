import Foundation
import SwiftUI
import Domain
import Utilities

/// Simplified account representation for expense linking
public struct ExpenseAccount: Identifiable, Sendable {
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

/// Display item for expenses in the list view
public struct ExpenseDisplayItem: Identifiable, Sendable {
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

    /// Create from ExpenseEntry
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

    /// Convert to Domain ExpenseEntry for business logic calculations.
    /// This ensures all calculations use the single source of truth in Domain.
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

    /// Monthly equivalent amount.
    /// Delegates to Domain's ExpenseEntry for the actual calculation.
    public var monthlyAmount: Decimal {
        toExpenseEntry().monthlyAmount
    }

    /// Annual equivalent amount.
    /// Delegates to Domain's ExpenseEntry for the actual calculation.
    public var annualAmount: Decimal {
        toExpenseEntry().annualAmount
    }

    /// Get the category for this expense
    public var category: ExpenseCategory? {
        guard let categoryId else { return nil }
        return ExpenseCategory.defaultCategory(for: categoryId)
    }
}

/// Input for creating/updating expenses
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

    /// Create from existing display item for editing
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

    /// Check if input is valid for saving
    public var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && amount > 0
    }
}

/// Grouped expenses by category for display
public struct ExpenseGroup: Identifiable, Sendable {
    /// Stable UUID for truly uncategorized expenses (where categoryId is nil)
    public static let uncategorizedId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    public let id: UUID
    public let category: ExpenseCategory?
    public var expenses: [ExpenseDisplayItem]

    /// Initialize with explicit id (for unknown categories that have a categoryId but no matching category)
    public init(id: UUID, category: ExpenseCategory?, expenses: [ExpenseDisplayItem]) {
        self.id = id
        self.category = category
        self.expenses = expenses
    }

    /// Initialize using category's id or uncategorizedId sentinel
    public init(category: ExpenseCategory?, expenses: [ExpenseDisplayItem]) {
        self.id = category?.id ?? Self.uncategorizedId
        self.category = category
        self.expenses = expenses
    }

    /// Total monthly amount for this group (enabled expenses only)
    public var totalMonthly: Decimal {
        expenses
            .filter { $0.isEnabled }
            .reduce(Decimal.zero) { $0 + $1.monthlyAmount }
    }

    /// Total annual amount for this group (enabled expenses only)
    public var totalAnnual: Decimal {
        expenses
            .filter { $0.isEnabled }
            .reduce(Decimal.zero) { $0 + $1.annualAmount }
    }

    /// Count of enabled expenses
    public var enabledCount: Int {
        expenses.count(where: \.isEnabled)
    }
}

/// ViewModel for the Expenses feature
@MainActor
@Observable
public final class ExpensesViewModel {
    // MARK: - Data

    /// All expenses (loaded from main app)
    public var expenses: [ExpenseDisplayItem] = []

    /// All available categories (defaults + custom)
    public var categories: [ExpenseCategory] = ExpenseCategory.defaults

    /// Custom categories (user-created)
    public var customCategories: [ExpenseCategory] = []

    /// User's selected currency
    public var currency: Currency = .usd

    /// Available accounts for linking expenses
    public var accounts: [ExpenseAccount] = []

    // MARK: - UI State

    /// Selected view frequency (monthly/annual)
    public var selectedFrequencyView: Frequency = .monthly

    /// Expanded category IDs
    public var expandedCategories: Set<UUID> = []

    /// Show add expense sheet
    public var showAddExpense = false

    /// Currently editing expense (nil = adding new)
    public var editingExpense: ExpenseDisplayItem?

    /// Show category management
    public var showCategoryManagement = false

    /// Search text
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

    /// Add a custom category (optimistic local update + persistence)
    public func addCategory(id: UUID, name: String, icon: String, colorHex: String) async {
        // Add to local state immediately for instant UI feedback
        let newCategory = ExpenseCategory.custom(id: id, name: name, icon: icon, colorHex: colorHex, sortOrder: 100)
        customCategories.append(newCategory)
        // Persist
        await onAddCategory?(id, name, icon, colorHex)
    }

    // MARK: - Computed Properties

    /// All categories including custom ones
    public var allCategories: [ExpenseCategory] {
        (ExpenseCategory.defaults + customCategories).sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Total monthly expenses (enabled only)
    public var totalMonthlyExpenses: Decimal {
        expenses
            .filter { $0.isEnabled }
            .reduce(Decimal.zero) { $0 + $1.monthlyAmount }
    }

    /// Total annual expenses (enabled only)
    public var totalAnnualExpenses: Decimal {
        expenses
            .filter { $0.isEnabled }
            .reduce(Decimal.zero) { $0 + $1.annualAmount }
    }

    /// Display total based on selected frequency
    public var displayTotal: Decimal {
        selectedFrequencyView == .monthly ? totalMonthlyExpenses : totalAnnualExpenses
    }

    /// Expenses grouped by category
    public var expenseGroups: [ExpenseGroup] {
        let filtered = filteredExpenses
        var groups: [UUID: [ExpenseDisplayItem]] = [:]
        var uncategorized: [ExpenseDisplayItem] = []

        for expense in filtered {
            if let categoryId = expense.categoryId {
                groups[categoryId, default: []].append(expense)
            } else {
                uncategorized.append(expense)
            }
        }

        var result: [ExpenseGroup] = []
        var handledCategoryIds: Set<UUID> = []

        // Add groups for each known category that has expenses
        for category in allCategories {
            if let expenses = groups[category.id], !expenses.isEmpty {
                result.append(ExpenseGroup(category: category, expenses: expenses))
                handledCategoryIds.insert(category.id)
            }
        }

        // Add groups for expenses with unknown category IDs (category was deleted or not loaded)
        // Use the original categoryId as the group id for stable expand/collapse
        for (categoryId, expenses) in groups where !handledCategoryIds.contains(categoryId) {
            result.append(ExpenseGroup(id: categoryId, category: nil, expenses: expenses))
        }

        // Add uncategorized group if any
        if !uncategorized.isEmpty {
            result.append(ExpenseGroup(category: nil, expenses: uncategorized))
        }

        return result
    }

    /// Filtered expenses based on search
    public var filteredExpenses: [ExpenseDisplayItem] {
        guard !searchText.isEmpty else { return expenses }
        return expenses.filter { expense in
            // Search by name
            if expense.name.localizedStandardContains(searchText) { return true }
            // Search by category name (including custom categories)
            if let categoryId = expense.categoryId,
               let category = allCategories.first(where: { $0.id == categoryId }),
               category.name.localizedStandardContains(searchText) {
                return true
            }
            // Search by notes
            if let notes = expense.notes, notes.localizedStandardContains(searchText) { return true }
            return false
        }
    }

    // MARK: - Actions

    public func toggleCategory(_ categoryId: UUID) {
        if expandedCategories.contains(categoryId) {
            expandedCategories.remove(categoryId)
        } else {
            expandedCategories.insert(categoryId)
        }
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
            // Update existing expense - update local state immediately for instant UI feedback
            if let index = expenses.firstIndex(where: { $0.id == existingId }) {
                expenses[index] = ExpenseDisplayItem(
                    id: existingId,
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
            await onUpdateExpense?(input)
        } else {
            // Add new expense - create local item immediately
            let newExpense = ExpenseDisplayItem(
                id: UUID(),
                name: input.name,
                amount: input.amount,
                frequency: input.frequency,
                icon: input.icon,
                categoryId: input.categoryId,
                linkedAccountId: input.linkedAccountId,
                isEnabled: input.isEnabled,
                notes: input.notes
            )
            expenses.append(newExpense)
            await onAddExpense?(input)
        }
        showAddExpense = false
        editingExpense = nil
    }

    public func deleteExpense(_ id: UUID) async {
        // Remove from local state immediately for instant UI feedback
        expenses.removeAll { $0.id == id }
        await onDeleteExpense?(id)
    }

    public func toggleExpenseEnabled(_ expense: ExpenseDisplayItem) async {
        // Update local state immediately for instant UI feedback
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = ExpenseDisplayItem(
                id: expense.id,
                name: expense.name,
                amount: expense.amount,
                frequency: expense.frequency,
                icon: expense.icon,
                categoryId: expense.categoryId,
                linkedAccountId: expense.linkedAccountId,
                isEnabled: !expense.isEnabled,
                notes: expense.notes
            )
        }
        await onToggleExpense?(expense.id, !expense.isEnabled)
    }
}
