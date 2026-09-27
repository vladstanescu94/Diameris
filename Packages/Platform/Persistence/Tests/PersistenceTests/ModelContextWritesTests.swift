import Foundation
import SwiftData
import Testing
@testable import Persistence

/// Exercises the app's SwiftData write paths against a fresh in-memory store per test.
@MainActor
struct ModelContextWritesTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    init() throws {
        container = try makeInMemoryContainer()
    }

    private func all<T: PersistentModel>(_ type: T.Type) throws -> [T] {
        try context.all(type)
    }

    // MARK: - Onboarding

    private static let primary = AccountEntry.primary()
    private static let joint = AccountEntry(name: "Joint", accountType: .joint, currentBalance: 150)

    private static func onboardingResult(name: String = "Ana") -> OnboardingResult {
        OnboardingResult(
            name: name,
            currencyCode: "EUR",
            incomeName: "Salary",
            monthlyIncome: 5000,
            expenses: [
                ExpenseEntry(name: "Rent", amount: 1500, icon: "house.fill"),
                ExpenseEntry(name: "Food", amount: 600, icon: "cart.fill", linkedAccountId: joint.id)
            ],
            accounts: [primary, joint],
            savingsAllocation: SavingsAllocationEntry(percentage: 0.3, allocationMode: .split),
            remainingMoneyDestination: .personal
        )
    }

    @Test func saveOnboardingPersistsTheWholeResult() throws {
        try context.saveOnboarding(Self.onboardingResult())

        let profile = try #require(try all(UserProfile.self).first)
        #expect(profile.name == "Ana")
        #expect(profile.currencyCode == "EUR")
        #expect(profile.remainingMoneyDestination == .personal)

        #expect(try all(Income.self).map(\.amount) == [5000])

        let accounts = try all(Account.self).sorted { $0.sortOrder < $1.sortOrder }
        #expect(accounts.map(\.name) == [Self.primary.name, "Joint"])
        #expect(accounts.map(\.currentBalance) == [Self.primary.currentBalance, 150])

        let allocation = try #require(try all(SavingsAllocation.self).first)
        #expect(allocation.percentage == 0.3)
        #expect(allocation.allocationMode == .split)
    }

    @Test func onboardingExpenseLinksResolveToStoredAccounts() throws {
        try context.saveOnboarding(Self.onboardingResult())

        let food = try #require(try all(Expense.self).first { $0.name == "Food" })
        let linkedId = try #require(food.linkedAccountId)
        let accountIds = Set(try all(Account.self).map(\.id))
        #expect(accountIds.contains(linkedId), "Food must still point at the stored Joint account")
    }

    @Test func rerunningOnboardingReplacesExistingData() throws {
        try context.saveOnboarding(Self.onboardingResult(name: "First"))
        try context.insertCustomCategory(id: UUID(), name: "Pets", icon: "pawprint", colorHex: "#FF0000")

        try context.saveOnboarding(Self.onboardingResult(name: "Second"))

        #expect(try all(UserProfile.self).map(\.name) == ["Second"])
        #expect(try all(Income.self).count == 1)
        #expect(try all(Account.self).count == 2)
        #expect(try all(Expense.self).count == 2)
        #expect(try all(SavingsAllocation.self).count == 1)
        #expect(try all(CustomCategory.self).isEmpty)
    }

    @Test func deleteAllDataEmptiesEveryModel() throws {
        try context.saveOnboarding(Self.onboardingResult())
        try context.insertCustomCategory(id: UUID(), name: "Pets", icon: "pawprint", colorHex: "#FF0000")
        context.insert(MonthlyRecord(month: .now, incomeAmount: 5000, totalExpenses: 2100, totalSavings: 900, remainingMoney: 2000))
        try context.save()
        for model in PersistenceSchema.models {
            try #require(try !all(model).isEmpty, "\(model) must be seeded for this test to prove anything")
        }

        try context.deleteAllData()

        for model in PersistenceSchema.models {
            #expect(try all(model).isEmpty, "\(model) should be empty")
        }
    }

    // MARK: - Expenses

    @Test func updateExpenseChangesOnlyTheMatchingExpense() throws {
        let rent = ExpenseEntry(name: "Rent", amount: 1500, icon: "house.fill")
        let gym = ExpenseEntry(name: "Gym", amount: 100, icon: "figure.run")
        try context.insertExpense(rent)
        try context.insertExpense(gym)

        var edited = rent
        edited.amount = 1700
        edited.frequency = .annual
        edited.notes = "New lease"
        try context.updateExpense(edited)

        let stored = Dictionary(uniqueKeysWithValues: try all(Expense.self).map { ($0.id, $0.toEntry()) })
        #expect(stored[rent.id] == edited)
        #expect(stored[gym.id] == gym)
    }

    @Test func updatingAMissingExpenseThrowsNotFound() throws {
        let missing = ExpenseEntry(name: "Ghost", amount: 1, icon: "questionmark")
        #expect(throws: PersistenceError.notFound(missing.id)) {
            try context.updateExpense(missing)
        }
    }

    @Test func deleteAndToggleExpenseById() throws {
        let rent = ExpenseEntry(name: "Rent", amount: 1500, icon: "house.fill")
        let gym = ExpenseEntry(name: "Gym", amount: 100, icon: "figure.run")
        try context.insertExpense(rent)
        try context.insertExpense(gym)

        try context.setExpenseEnabled(id: gym.id, isEnabled: false)
        try context.deleteExpense(id: rent.id)
        try context.deleteExpense(id: UUID()) // unknown id: no-op, no throw

        let remaining = try all(Expense.self)
        #expect(remaining.map(\.id) == [gym.id])
        #expect(remaining.first?.isEnabled == false)
    }

    @Test func deletingACategoryUncategorizesItsExpenses() throws {
        let id = UUID()
        try context.insertCustomCategory(id: id, name: "Pets", icon: "pawprint", colorHex: "#FF0000")
        try context.insertExpense(ExpenseEntry(name: "Vet", amount: 90, icon: "cross", categoryId: id))
        try context.insertExpense(ExpenseEntry(name: "Rent", amount: 1500, icon: "house", categoryId: ExpenseCategory.housing.id))

        try context.deleteCustomCategory(id: id)

        #expect(try all(CustomCategory.self).isEmpty)
        let categories = Dictionary(uniqueKeysWithValues: try all(Expense.self).map { ($0.name, $0.categoryId) })
        #expect(categories == ["Vet": nil, "Rent": ExpenseCategory.housing.id])
    }

    // MARK: - New Month

    /// The same pipeline MainTabView runs: Domain computes balances from the stored accounts,
    /// Persistence applies them. The Joint account is never reconciled but receives Food.
    @Test func newMonthUpdatesIncomeAndBalancesIncludingUnreconciledJoint() throws {
        try context.saveOnboarding(Self.onboardingResult())
        let entries = try all(Account.self).map { $0.toEntry() }
        let expenses = try all(Expense.self).map { $0.toEntry() }

        let plan = TransferCalculator.calculate(
            income: 5200,
            expenses: expenses,
            allocation: SavingsAllocationEntry(),
            accounts: entries,
            remainingDestination: .primarySavings
        )
        let balances = BalanceReconciler.updatedBalances(
            plan: plan,
            accounts: entries,
            reconciledBalances: [Self.primary.id: 900]
        )

        try context.applyNewMonth(income: 5200, balances: balances)

        #expect(try all(Income.self).map(\.amount) == [5200])
        let stored = Dictionary(uniqueKeysWithValues: try all(Account.self).map { ($0.id, $0.currentBalance) })
        #expect(stored[Self.joint.id] == 750, "Joint keeps its 150 and receives the 600 Food transfer")
        #expect(stored[Self.primary.id] == balances[Self.primary.id])
    }

    @Test func newMonthLeavesAccountsWithoutANewBalanceUntouched() throws {
        try context.saveOnboarding(Self.onboardingResult())

        try context.applyNewMonth(income: 5000, balances: [Self.primary.id: 42, UUID(): 999])

        let stored = Dictionary(uniqueKeysWithValues: try all(Account.self).map { ($0.id, $0.currentBalance) })
        #expect(stored == [Self.primary.id: 42, Self.joint.id: 150])
    }

    // MARK: - Settings

    @Test func saveSettingsRoundTripsProfileAndAllocation() throws {
        try context.saveOnboarding(Self.onboardingResult())
        let allocation = SavingsAllocationEntry(
            percentage: 0.2,
            boostEnabled: true,
            boostMultiplier: 2,
            allocationMode: .split,
            savingsInputMode: .fixedAmount,
            fixedAmount: 300,
            splitEmergencyInputMode: .percentage,
            splitEmergencyAmount: 50,
            splitEmergencyPercentage: 0.12,
            splitSavingsInputMode: .fixedAmount,
            splitSavingsAmount: 250,
            splitSavingsPercentage: 0.18
        )

        try context.saveSettings(
            name: "Ana Maria",
            currencyCode: "RON",
            remainingMoneyDestination: .primary,
            savingsAllocation: allocation
        )

        let profile = try #require(try all(UserProfile.self).first)
        #expect(profile.name == "Ana Maria")
        #expect(profile.currencyCode == "RON")
        #expect(profile.remainingMoneyDestination == .primary)

        let stored = try #require(try all(SavingsAllocation.self).first).toEntry()
        #expect(try all(SavingsAllocation.self).count == 1)
        #expect(stored.percentage == allocation.percentage)
        #expect(stored.boostEnabled == allocation.boostEnabled)
        #expect(stored.boostMultiplier == allocation.boostMultiplier)
        #expect(stored.allocationMode == allocation.allocationMode)
        #expect(stored.savingsInputMode == allocation.savingsInputMode)
        #expect(stored.fixedAmount == allocation.fixedAmount)
        #expect(stored.splitEmergencyInputMode == allocation.splitEmergencyInputMode)
        #expect(stored.splitEmergencyAmount == allocation.splitEmergencyAmount)
        #expect(stored.splitEmergencyPercentage == allocation.splitEmergencyPercentage)
        #expect(stored.splitSavingsInputMode == allocation.splitSavingsInputMode)
        #expect(stored.splitSavingsAmount == allocation.splitSavingsAmount)
        #expect(stored.splitSavingsPercentage == allocation.splitSavingsPercentage)
    }

    @Test func saveSettingsCreatesTheAllocationWhenMissing() throws {
        try context.saveSettings(
            name: "Ana",
            currencyCode: "EUR",
            remainingMoneyDestination: .personal,
            savingsAllocation: SavingsAllocationEntry(percentage: 0.4)
        )

        #expect(try all(SavingsAllocation.self).map(\.percentage) == [0.4])
    }

    @Test func markingAPrimarySavingsAccountClearsTheOthers() throws {
        let first = AccountEntry(name: "Savings A", accountType: .savings, isPrimarySavings: true)
        let second = AccountEntry(name: "Savings B", accountType: .savings)
        try context.saveOnboarding(OnboardingResult(
            name: "Ana", currencyCode: "EUR", incomeName: "Salary", monthlyIncome: 1000,
            expenses: [], accounts: [first, second],
            savingsAllocation: SavingsAllocationEntry(), remainingMoneyDestination: .primarySavings
        ))

        var promoted = second
        promoted.isPrimarySavings = true
        promoted.currentBalance = 75
        try context.updateAccount(promoted)

        let stored = Dictionary(uniqueKeysWithValues: try all(Account.self).map { ($0.id, $0) })
        #expect(stored[second.id]?.isPrimarySavings == true)
        #expect(stored[second.id]?.currentBalance == 75)
        #expect(stored[first.id]?.isPrimarySavings == false)
    }

    // MARK: - Settings rules

    private static let emergency = AccountEntry(name: "Emergency", accountType: .emergency, emergencyMultiplier: 3)
    private static let savings = AccountEntry(name: "Savings", accountType: .savings, isPrimarySavings: true)

    private func onboardWithEveryRole() throws {
        try context.saveOnboarding(OnboardingResult(
            name: "Ana", currencyCode: "RON", incomeName: "Salary", monthlyIncome: 8500,
            expenses: [], accounts: [Self.primary, Self.emergency, Self.savings],
            savingsAllocation: SavingsAllocationEntry(), remainingMoneyDestination: .primarySavings
        ))
    }

    /// A primary account turned into auto-save savings would receive its own savings, which the
    /// reconciler then overwrites — the month's savings would vanish from every balance.
    @Test func thePrimaryAccountKeepsItsRole() throws {
        try onboardWithEveryRole()
        var edited = Self.primary
        edited.accountType = .savings
        edited.isPrimarySavings = true

        try context.updateAccount(edited)

        let stored = try #require(try all(Account.self).first { $0.id == Self.primary.id })
        #expect(stored.accountType == .primary)
        #expect(stored.isPrimarySavings == false)
        #expect(try all(Account.self).first { $0.id == Self.savings.id }?.isPrimarySavings == true)
    }

    @Test func aSecondEmergencyAccountIsRejected() throws {
        try onboardWithEveryRole()
        var edited = Self.savings
        edited.accountType = .emergency

        #expect(throws: PersistenceError.accountTypeNotAllowed(.emergency)) {
            try context.updateAccount(edited)
        }
        #expect(try all(Account.self).first { $0.id == Self.savings.id }?.accountType == .savings)
    }

    @Test func saveSettingsTurnsOffABoostAboveAvailableIncome() throws {
        try onboardWithEveryRole()

        try context.saveSettings(
            name: "Ana", currencyCode: "RON", remainingMoneyDestination: .primarySavings,
            savingsAllocation: SavingsAllocationEntry(percentage: 0.5, boostEnabled: true, boostMultiplier: 3)
        )

        #expect(try all(SavingsAllocation.self).first?.boostEnabled == false)
    }

    @Test func saveSettingsKeepsRemainingMoneyInPrimaryWhenTheDestinationHasNoAccount() throws {
        try onboardWithEveryRole()

        try context.saveSettings(
            name: "Ana", currencyCode: "RON", remainingMoneyDestination: .personal,
            savingsAllocation: SavingsAllocationEntry()
        )

        #expect(try all(UserProfile.self).first?.remainingMoneyDestination == .primary)
    }
}
