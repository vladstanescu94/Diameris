import Foundation
import SwiftData
import UIKit
import Utilities

/// Where remaining money after expenses and savings should go.
public enum RemainingMoneyDestination: String, CaseIterable, Identifiable, Codable, Sendable {
    case primarySavings  // Add to the primary savings account
    case personal        // Transfer to first personal account
    case primary         // Keep in primary account

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .primarySavings: return "Primary Savings".localized
        case .personal: return "Personal Account".localized
        case .primary: return "Keep in Primary".localized
        }
    }

    public var description: String {
        switch self {
        case .primarySavings: return "Add to your savings for future goals".localized
        case .personal: return "For flexible spending".localized
        case .primary: return "Leave in your main account".localized
        }
    }
}

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

    /// Savings allocation (percentage + boost)
    public var savingsAllocation = SavingsAllocationEntry()

    /// Where remaining money should go after expenses and savings
    public var remainingMoneyDestination: RemainingMoneyDestination = .primarySavings

    // MARK: - Flow State

    public var currentStep: OnboardingStep = .welcome

    public enum OnboardingStep: Int, CaseIterable, Sendable {
        case welcome
        case name
        case income
        case accounts      // Create accounts (with prompts for emergency + savings)
        case savings       // Set savings percentage (renamed from savingsGoals)
        case expenses      // Link expenses to accounts
        case transferPlan  // Review and set remaining money destination
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
        case .accounts:
            return accounts.contains { $0.isPrimary }
        case .savings:
            return true // Savings percentage is optional
        case .expenses:
            return true // Expenses are optional
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

    /// The emergency account (only one allowed)
    public var emergencyAccount: AccountEntry? {
        accounts.first { $0.accountType == .emergency }
    }

    /// The primary savings account that receives auto-allocation
    public var primarySavingsAccount: AccountEntry? {
        accounts.first { $0.isPrimarySavings }
    }

    /// The first personal account for flexible spending
    public var personalAccount: AccountEntry? {
        accounts.first { $0.accountType == .personal }
    }

    /// Whether an emergency account exists
    public var hasEmergencyAccount: Bool {
        emergencyAccount != nil
    }

    /// Whether a primary savings account exists
    public var hasPrimarySavingsAccount: Bool {
        primarySavingsAccount != nil
    }

    /// Calculated transfer plan based on current inputs
    public var transferPlan: TransferPlan {
        TransferCalculator.calculate(
            income: monthlyIncome,
            expenses: expenses,
            allocation: savingsAllocation,
            accounts: accounts,
            remainingDestination: remainingMoneyDestination
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
        // Save user profile with remaining money destination
        let userProfile = UserProfile(
            name: trimmedName,
            currencyCode: currency.rawValue,
            remainingMoneyDestination: remainingMoneyDestination.rawValue
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

        // Save accounts with all properties
        for (index, accountEntry) in accounts.enumerated() {
            let account = Account(from: accountEntry, sortOrder: index)
            context.insert(account)
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
// - Models/SavingsAllocationEntry.swift
