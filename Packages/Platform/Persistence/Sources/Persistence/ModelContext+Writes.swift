import Foundation
import SwiftData
import Domain

public enum PersistenceError: Error, Equatable {
    case notFound(UUID)
    case accountTypeNotAllowed(AccountType)
}

/// Every `@Model` type, shared by the app container, tests and `deleteAllData()`.
/// Entities are keyed by class name: never rename or remove one (the store would fail to open).
public enum PersistenceSchema {
    public static let models: [any PersistentModel.Type] = [
        UserProfile.self,
        Income.self,
        Expense.self,
        Account.self,
        SavingsAllocation.self,
        MonthlyRecord.self,
        CustomCategory.self
    ]
}

// MARK: - Write Operations
// Each operation saves once; on failure the context is rolled back and the error rethrown.

public extension ModelContext {

    // MARK: Onboarding

    /// Replaces all stored data with the onboarding result, so a re-run never leaves two
    /// profiles or duplicate accounts behind.
    func saveOnboarding(_ result: OnboardingResult) throws {
        try deleteAllModels()

        insert(UserProfile(
            name: result.name,
            currencyCode: result.currencyCode,
            remainingMoneyDestination: result.remainingMoneyDestination
        ))
        insert(Income(name: result.incomeName, amount: result.monthlyIncome, frequency: .monthly))
        for (index, entry) in result.expenses.enumerated() {
            insert(Expense(from: entry, sortOrder: index))
        }
        for (index, entry) in result.accounts.enumerated() {
            insert(Account(from: entry, sortOrder: index))
        }
        insert(SavingsAllocation(from: result.savingsAllocation))

        try commit()
    }

    func deleteAllData() throws {
        try deleteAllModels()
        try commit()
    }

    // MARK: Expenses

    func insertExpense(_ entry: ExpenseEntry) throws {
        insert(Expense(from: entry))
        try commit()
    }

    func updateExpense(_ entry: ExpenseEntry) throws {
        let expense = try existingExpense(id: entry.id)
        expense.name = entry.name
        expense.amount = entry.amount
        expense.frequency = entry.frequency
        expense.icon = entry.icon
        expense.categoryId = entry.categoryId
        expense.linkedAccountId = entry.linkedAccountId
        expense.isEnabled = entry.isEnabled
        expense.notes = entry.notes
        try commit()
    }

    func setExpenseEnabled(id: UUID, isEnabled: Bool) throws {
        try existingExpense(id: id).isEnabled = isEnabled
        try commit()
    }

    /// Deleting an id that no longer exists is a no-op.
    func deleteExpense(id: UUID) throws {
        guard let expense = try first(Expense.self, where: #Predicate { $0.id == id }) else { return }
        delete(expense)
        try commit()
    }

    // MARK: Custom Categories

    func insertCustomCategory(id: UUID, name: String, icon: String, colorHex: String) throws {
        insert(CustomCategory(id: id, name: name, icon: icon, colorHex: colorHex))
        try commit()
    }

    /// Also uncategorizes the category's expenses, so none keeps pointing at a deleted id.
    func deleteCustomCategory(id: UUID) throws {
        guard let category = try first(CustomCategory.self, where: #Predicate { $0.id == id }) else { return }
        delete(category)
        for expense in try fetch(FetchDescriptor<Expense>()) where expense.categoryId == id {
            expense.categoryId = nil
        }
        try commit()
    }

    // MARK: New Month

    /// Accounts not in `balances` keep their balance; ids with no stored account are ignored.
    func applyNewMonth(income: Decimal, balances: [UUID: Decimal], savingsBoostEnabled: Bool? = nil) throws {
        if let storedIncome = try first(Income.self) {
            storedIncome.amount = income
        }
        for account in try fetch(FetchDescriptor<Account>()) {
            if let balance = balances[account.id] {
                account.currentBalance = balance
            }
        }
        if let savingsBoostEnabled {
            try applySavingsBoost(savingsBoostEnabled)
        }
        try commit()
    }

    // MARK: Savings Boost

    /// Turning boost on is ignored when the boosted rate would exceed available income.
    func setSavingsBoostEnabled(_ enabled: Bool) throws {
        try applySavingsBoost(enabled)
        try commit()
    }

    // MARK: Settings

    /// Creates the allocation if none is stored yet, so edits are never silently dropped.
    func saveSettings(
        name: String,
        currencyCode: String,
        remainingMoneyDestination: RemainingMoneyDestination,
        savingsAllocation entry: SavingsAllocationEntry
    ) throws {
        let accounts = try fetch(FetchDescriptor<Account>()).map { $0.toEntry() }

        if let profile = try first(UserProfile.self) {
            profile.name = name
            profile.currencyCode = currencyCode
            profile.remainingMoneyDestination = accounts.resolvedRemainingDestination(remainingMoneyDestination)
        }

        let safeEntry = entry.withSafeBoost
        if let allocation = try first(SavingsAllocation.self) {
            allocation.update(from: safeEntry)
        } else {
            insert(SavingsAllocation(from: safeEntry))
        }
        try commit()
    }

    /// Keeps `sortOrder` and `isPrimary`; the primary account's type can't change, and a unique
    /// type already held by another account is rejected. Only one account can be primary
    /// savings, so marking this one clears the flag on the others.
    func updateAccount(_ entry: AccountEntry) throws {
        let id = entry.id
        guard let account = try first(Account.self, where: #Predicate { $0.id == id }) else {
            throw PersistenceError.notFound(id)
        }
        var entry = entry
        if account.isPrimary {
            entry.accountType = .primary
            entry.isPrimarySavings = false
        } else {
            let accounts = try fetch(FetchDescriptor<Account>()).map { $0.toEntry() }
            guard accounts.canAssign(entry.accountType, toAccount: id) else {
                throw PersistenceError.accountTypeNotAllowed(entry.accountType)
            }
        }
        account.name = entry.name
        account.purpose = entry.purpose
        account.accountType = entry.accountType
        account.isPrimarySavings = entry.isPrimarySavings
        account.emergencyMultiplier = entry.emergencyMultiplier
        account.emergencyHardCap = entry.emergencyHardCap
        account.currentBalance = entry.currentBalance

        if entry.isPrimarySavings {
            for other in try fetch(FetchDescriptor<Account>()) where other.id != id {
                other.isPrimarySavings = false
            }
        }
        try commit()
    }
}

// MARK: - Helpers

extension ModelContext {
    fileprivate func applySavingsBoost(_ enabled: Bool) throws {
        guard let allocation = try first(SavingsAllocation.self) else { return }
        var entry = allocation.toEntry()
        entry.boostEnabled = enabled
        allocation.update(from: entry.withSafeBoost)
    }

    func commit() throws {
        do {
            try save()
        } catch {
            rollback()
            throw error
        }
    }

    func first<T: PersistentModel>(_ type: T.Type, where predicate: Predicate<T>? = nil) throws -> T? {
        var descriptor = FetchDescriptor<T>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try fetch(descriptor).first
    }

    func existingExpense(id: UUID) throws -> Expense {
        guard let expense = try first(Expense.self, where: #Predicate { $0.id == id }) else {
            throw PersistenceError.notFound(id)
        }
        return expense
    }

    func deleteAllModels() throws {
        for model in PersistenceSchema.models {
            try deleteAll(model)
        }
    }

    func deleteAll<T: PersistentModel>(_ model: T.Type) throws {
        try delete(model: model)
    }
}
