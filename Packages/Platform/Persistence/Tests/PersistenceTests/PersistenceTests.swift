import Foundation
import Testing
@testable import Persistence
import Domain

// Use ExpenseCategory from Persistence to avoid ambiguity
private typealias Category = ExpenseCategory

/// Tests for Persistence package - validates SwiftData entity models
@Suite("Persistence Tests")
struct PersistenceTests {

    // MARK: - Expense Entity

    @Suite("Expense Entity")
    struct ExpenseTests {

        @Test("Creates expense with default values")
        func createExpense() {
            let expense = Expense(
                name: "Gas",
                amount: 300,
                icon: "car.fill"
            )

            #expect(expense.name == "Gas")
            #expect(expense.amount == 300)
            #expect(expense.frequency == .monthly)
            #expect(expense.isEnabled == true)
            #expect(expense.categoryId == nil)
        }

        @Test("Creates expense with category")
        func createExpenseWithCategory() {
            let expense = Expense(
                name: "Gas",
                amount: 300,
                icon: "car.fill",
                frequency: .monthly,
                categoryId: Category.autoTransport.id,
                subcategoryId: Subcategory.defaults(for: Category.autoTransport.id).first?.id
            )

            #expect(expense.categoryId == Category.autoTransport.id)
            #expect(expense.subcategoryId != nil)
        }

        @Test("Creates expense with annual frequency")
        func createAnnualExpense() {
            let expense = Expense(
                name: "Insurance",
                amount: 2400,
                icon: "shield.fill",
                frequency: .annual
            )

            #expect(expense.frequency == .annual)
            // Using approximate comparison due to Decimal division precision
            #expect(abs(expense.monthlyAmount - 200) < Decimal(string: "0.01")!)
            #expect(expense.annualAmount == 2400)
        }

        @Test("Converts to ExpenseEntry correctly")
        func convertsToEntry() {
            let categoryId = Category.autoTransport.id
            let expense = Expense(
                name: "Gas",
                amount: 300,
                icon: "car.fill",
                frequency: .monthly,
                categoryId: categoryId,
                notes: "Regular gas"
            )

            let entry = expense.toEntry()

            #expect(entry.name == "Gas")
            #expect(entry.amount == 300)
            #expect(entry.frequency == .monthly)
            #expect(entry.categoryId == categoryId)
            #expect(entry.notes == "Regular gas")
        }

        @Test("Creates from ExpenseEntry correctly")
        func createsFromEntry() {
            let entry = ExpenseEntry(
                name: "Insurance",
                amount: 2400,
                frequency: .annual,
                icon: "shield.fill",
                categoryId: Category.autoTransport.id,
                notes: "Annual payment"
            )

            let expense = Expense(from: entry)

            #expect(expense.name == "Insurance")
            #expect(expense.amount == 2400)
            #expect(expense.frequency == .annual)
            #expect(expense.categoryId == Category.autoTransport.id)
            #expect(expense.notes == "Annual payment")
        }
    }

    // MARK: - Account Entity

    @Suite("Account Entity")
    struct AccountTests {

        @Test("Creates account with defaults")
        func createAccount() {
            let account = Account(name: "Checking")

            #expect(account.name == "Checking")
            #expect(account.isPrimary == false)
            #expect(account.accountType == .other)
            #expect(account.currentBalance == 0)
        }

        @Test("Converts to AccountEntry correctly")
        func convertsToEntry() {
            let account = Account(
                name: "Emergency",
                isPrimary: false,
                accountType: .emergency,
                emergencyMultiplier: 6.0,
                currentBalance: 5000
            )

            let entry = account.toEntry()

            #expect(entry.name == "Emergency")
            #expect(entry.accountType == .emergency)
            #expect(entry.emergencyMultiplier == 6.0)
            #expect(entry.currentBalance == 5000)
        }

        @Test("Emergency target calculation")
        func emergencyTarget() {
            let account = Account(
                name: "Emergency",
                accountType: .emergency,
                emergencyMultiplier: 6.0,
                currentBalance: 15000
            )

            let target = account.emergencyTarget(monthlyIncome: 5000)
            #expect(target == 30000)

            let progress = account.emergencyProgress(monthlyIncome: 5000)
            #expect(progress == 0.5)
        }
    }

    // MARK: - Income Entity

    @Suite("Income Entity")
    struct IncomeTests {

        @Test("Creates income with defaults")
        func createIncome() {
            let income = Income(amount: 5000)

            #expect(income.name == "Salary")
            #expect(income.amount == 5000)
            #expect(income.frequency == .monthly)
            #expect(income.isActive == true)
        }

        @Test("Monthly amount calculation")
        func monthlyAmount() {
            let monthlyIncome = Income(amount: 5000, frequency: .monthly)
            #expect(monthlyIncome.monthlyAmount == 5000)

            let annualIncome = Income(amount: 60000, frequency: .annual)
            // Using approximate comparison due to Decimal division precision
            #expect(abs(annualIncome.monthlyAmount - 5000) < Decimal(string: "0.01")!)
        }
    }

    // MARK: - SavingsAllocation Entity

    @Suite("SavingsAllocation Entity")
    struct SavingsAllocationTests {

        @Test("Creates allocation with defaults")
        func createAllocation() {
            let allocation = SavingsAllocation()

            #expect(allocation.percentage == 0.25)
            #expect(allocation.boostEnabled == false)
            #expect(allocation.boostMultiplier == 3.0)
        }

        @Test("Effective percentage without boost")
        func effectivePercentageNoBoost() {
            let allocation = SavingsAllocation(percentage: 0.20)
            #expect(allocation.effectivePercentage == 0.20)
        }

        @Test("Effective percentage with boost")
        func effectivePercentageWithBoost() {
            let allocation = SavingsAllocation(
                percentage: 0.20,
                boostEnabled: true,
                boostMultiplier: 2.0
            )
            #expect(allocation.effectivePercentage == 0.40)
        }

        @Test("Converts to SavingsAllocationEntry correctly")
        func convertsToEntry() {
            let allocation = SavingsAllocation(percentage: 0.30, boostEnabled: true)
            let entry = allocation.toEntry()

            #expect(entry.percentage == 0.30)
            #expect(entry.boostEnabled == true)
        }
    }

    // MARK: - CustomCategory Entity

    @Suite("CustomCategory Entity")
    struct CustomCategoryTests {

        @Test("Creates custom category")
        func createCustomCategory() {
            let category = CustomCategory(
                name: "Custom",
                icon: "star.fill",
                colorHex: "#FF0000"
            )

            #expect(category.name == "Custom")
            #expect(category.icon == "star.fill")
            #expect(category.colorHex == "#FF0000")
            #expect(category.sortOrder == 100)
        }

        @Test("Converts to Domain Category")
        func convertsToDomainCategory() {
            let customCategory = CustomCategory(
                name: "Custom",
                icon: "star.fill",
                colorHex: "#FF0000",
                sortOrder: 50
            )

            let domainCategory = customCategory.toCategory()

            #expect(domainCategory.name == "Custom")
            #expect(domainCategory.isDefault == false)
            #expect(domainCategory.sortOrder == 50)
        }
    }

    // MARK: - CustomSubcategory Entity

    @Suite("CustomSubcategory Entity")
    struct CustomSubcategoryTests {

        @Test("Creates custom subcategory")
        func createCustomSubcategory() {
            let categoryId = Category.autoTransport.id
            let subcategory = CustomSubcategory(
                name: "Custom Sub",
                categoryId: categoryId
            )

            #expect(subcategory.name == "Custom Sub")
            #expect(subcategory.categoryId == categoryId)
            #expect(subcategory.sortOrder == 100)
        }

        @Test("Converts to Domain Subcategory")
        func convertsToDomainSubcategory() {
            let categoryId = Category.autoTransport.id
            let customSub = CustomSubcategory(
                name: "Custom Sub",
                categoryId: categoryId,
                sortOrder: 50
            )

            let domainSub = customSub.toSubcategory()

            #expect(domainSub.name == "Custom Sub")
            #expect(domainSub.categoryId == categoryId)
            #expect(domainSub.isDefault == false)
        }
    }
}
