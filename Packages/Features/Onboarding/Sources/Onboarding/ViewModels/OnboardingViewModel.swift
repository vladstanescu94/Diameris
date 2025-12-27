import Foundation
import SwiftData
import UIKit
import Utilities

@MainActor
@Observable
public final class OnboardingViewModel {
    // MARK: - Collected Data

    public var name: String = ""
    public var currency: Currency = .fromLocale()
    public var monthlyIncome: Decimal = 0

    public var expenses: [ExpenseEntry] = [
        ExpenseEntry(name: "Food & Groceries".localized, amount: 0, icon: "cart.fill"),
        ExpenseEntry(name: "Rent / Housing".localized, amount: 0, icon: "house.fill"),
        ExpenseEntry(name: "Transportation".localized, amount: 0, icon: "car.fill"),
        ExpenseEntry(name: "Subscriptions".localized, amount: 0, icon: "repeat.circle.fill")
    ]

    public var accounts: [AccountEntry] = AccountEntry.defaults

    public var savingsGoals: [SavingsGoalEntry] = SavingsGoalEntry.defaults
    public var savingsAllocation = SavingsAllocationEntry()

    // MARK: - Flow State

    public var currentStep: OnboardingStep = .welcome

    public enum OnboardingStep: Int, CaseIterable, Sendable {
        case welcome
        case name
        case income
        case savingsGoals
        case expenses      // Expenses before accounts so user can link them
        case accounts
        case transferPlan
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
        case .welcome:
            return true
        case .name:
            return trimmedName.count >= 1 && trimmedName.count <= 50
        case .income:
            return monthlyIncome > 0
        case .savingsGoals:
            return true // Goals are optional
        case .expenses:
            return true // Expenses are optional
        case .accounts:
            return accounts.contains { $0.isPrimary }
        case .transferPlan:
            return true
        }
    }

    public var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Computed Properties

    /// All accounts including primary and additional
    public var allAccounts: [AccountEntry] {
        accounts
    }

    /// The primary account where salary lands
    public var primaryAccount: AccountEntry? {
        accounts.first { $0.isPrimary }
    }

    /// Calculated transfer plan based on current inputs
    public var transferPlan: TransferPlan {
        TransferCalculator.calculate(
            income: monthlyIncome,
            expenses: expenses,
            goals: savingsGoals,
            allocation: savingsAllocation,
            accounts: accounts
        )
    }

    // MARK: - Progress Tracking

    public var totalSteps: Int {
        OnboardingStep.allCases.count
    }

    public var currentStepIndex: Int {
        currentStep.rawValue
    }

    public var progress: Double {
        guard totalSteps > 1 else { return 0 }
        return Double(currentStepIndex) / Double(totalSteps - 1)
    }

    // MARK: - Persistence

    public func save(context: ModelContext) {
        // Save user profile
        let userProfile = UserProfile(
            name: trimmedName,
            currencyCode: currency.rawValue
        )
        context.insert(userProfile)

        // Save income
        let income = Income(
            name: "Salary".localized,
            amount: monthlyIncome,
            frequency: "monthly"
        )
        context.insert(income)

        // Save expenses
        for expense in expenses where expense.amount > 0 {
            let expenseModel = Expense(
                name: expense.name,
                amount: expense.amount,
                icon: expense.icon,
                frequency: "monthly",
                linkedAccountId: expense.linkedAccountId
            )
            context.insert(expenseModel)
        }

        // Save accounts with types
        for (index, accountEntry) in accounts.enumerated() {
            let account = Account(
                name: accountEntry.name,
                purpose: accountEntry.purpose,
                isPrimary: accountEntry.isPrimary,
                sortOrder: index
            )
            account.accountType = accountEntry.accountType
            context.insert(account)
        }

        // Save savings goals
        for goal in savingsGoals where goal.isActive {
            let savingsGoal = SavingsGoal(
                name: goal.name,
                icon: goal.icon,
                targetType: goal.targetType,
                targetValue: goal.targetValue,
                currentBalance: goal.currentBalance,
                priority: goal.priority,
                linkedAccountId: nil,
                isActive: goal.isActive
            )
            context.insert(savingsGoal)
        }

        // Save savings allocation
        let allocation = SavingsAllocation(
            percentage: savingsAllocation.percentage,
            boostEnabled: savingsAllocation.boostEnabled,
            boostMultiplier: savingsAllocation.boostMultiplier
        )
        context.insert(allocation)

        try? context.save()
    }
}

// Supporting types are defined in:
// - Models/ExpenseEntry.swift
// - Models/AccountEntry.swift
// - Models/SavingsGoalEntry.swift
// - Models/SavingsAllocationEntry.swift
