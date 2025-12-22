import Foundation
import SwiftData
import UIKit

@MainActor
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
        dismissKeyboard()
        // Delay to allow keyboard to dismiss before transition
        Task {
            try? await Task.sleep(for: .milliseconds(150))
            performAdvance()
        }
    }

    private func performAdvance() {
        guard let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
              currentIndex < OnboardingStep.allCases.count - 1 else {
            return
        }
        currentStep = OnboardingStep.allCases[currentIndex + 1]
    }

    public func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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

// Supporting types are defined in:
// - Models/ExpenseEntry.swift
// - Models/AccountEntry.swift
