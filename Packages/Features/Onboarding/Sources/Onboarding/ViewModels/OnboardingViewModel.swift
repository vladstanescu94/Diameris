import Foundation
import SwiftData

@Observable
public final class OnboardingViewModel {
    // MARK: - Collected Data

    public var name: String = ""
    public var currency: Currency = .fromLocale()
    public var monthlyIncome: Decimal = 0

    public var expenses: [ExpenseEntry] = [
        ExpenseEntry(name: String(localized: "Food & Groceries"), amount: 0, icon: "cart.fill"),
        ExpenseEntry(name: String(localized: "Rent / Housing"), amount: 0, icon: "house.fill"),
        ExpenseEntry(name: String(localized: "Transportation"), amount: 0, icon: "car.fill")
    ]

    public var primaryAccountName: String = String(localized: "Main Checking")
    public var additionalAccounts: [AccountEntry] = []

    // MARK: - Flow State

    public var currentStep: OnboardingStep = .name

    public enum OnboardingStep: Int, CaseIterable, Sendable {
        case name
        case income
        case expenses
        case accounts
        case complete
    }

    // MARK: - Initialization

    public init() {}

    // MARK: - Navigation

    public func advance() {
        guard let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
              currentIndex < OnboardingStep.allCases.count - 1 else {
            return
        }
        currentStep = OnboardingStep.allCases[currentIndex + 1]
    }

    public var canAdvance: Bool {
        switch currentStep {
        case .name:
            return trimmedName.count >= 1 && trimmedName.count <= 50
        case .income:
            return monthlyIncome > 0
        case .expenses:
            return true
        case .accounts:
            return !primaryAccountName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .complete:
            return true
        }
    }

    public var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Persistence

    public func save(context: ModelContext) {
        let userProfile = UserProfile(
            name: trimmedName,
            currencyCode: currency.rawValue
        )
        context.insert(userProfile)

        let income = Income(
            name: String(localized: "Salary"),
            amount: monthlyIncome,
            frequency: "monthly"
        )
        context.insert(income)

        for expense in expenses where expense.amount > 0 {
            let expenseModel = Expense(
                name: expense.name,
                amount: expense.amount,
                icon: expense.icon,
                frequency: "monthly"
            )
            context.insert(expenseModel)
        }

        let trimmedPrimaryName = primaryAccountName.trimmingCharacters(in: .whitespacesAndNewlines)
        let primaryAccount = Account(
            name: trimmedPrimaryName,
            purpose: nil,
            isPrimary: true,
            sortOrder: 0
        )
        context.insert(primaryAccount)

        for (index, accountEntry) in additionalAccounts.enumerated() {
            let account = Account(
                name: accountEntry.name,
                purpose: accountEntry.purpose,
                isPrimary: false,
                sortOrder: index + 1
            )
            context.insert(account)
        }

        try? context.save()
    }
}

// MARK: - Supporting Types

public struct ExpenseEntry: Identifiable, Sendable {
    public let id = UUID()
    public var name: String
    public var amount: Decimal
    public var icon: String

    public init(name: String, amount: Decimal, icon: String) {
        self.name = name
        self.amount = amount
        self.icon = icon
    }
}

public struct AccountEntry: Identifiable, Sendable {
    public let id = UUID()
    public var name: String
    public var purpose: String?

    public init(name: String, purpose: String? = nil) {
        self.name = name
        self.purpose = purpose
    }
}
