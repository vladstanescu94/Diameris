import Foundation
import SwiftData
import Observation
import Domain
import Utilities

/// Protocol for fetching data that Dashboard needs.
/// This allows the main app to provide SwiftData models.
public protocol DashboardDataProvider: Sendable {
    var userName: String { get }
    var monthlyIncome: Decimal { get }
    var currency: Currency { get }
    var accounts: [DashboardAccount] { get }
    var expenses: [DashboardExpense] { get }
    var savingsPercentage: Double { get }
    var savingsBoostEnabled: Bool { get }
    var savingsBoostMultiplier: Double { get }
    var remainingMoneyDestination: RemainingMoneyDestination { get }
}

/// Simplified account representation for Dashboard.
/// Business logic is delegated to Domain's AccountEntry to avoid duplication.
public struct DashboardAccount: Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let accountType: AccountType
    public let isPrimary: Bool
    public let isPrimarySavings: Bool
    public let emergencyMultiplier: Double?
    public let emergencyHardCap: Decimal?
    public var currentBalance: Decimal

    public init(
        id: UUID,
        name: String,
        accountType: AccountType,
        isPrimary: Bool,
        isPrimarySavings: Bool,
        emergencyMultiplier: Double?,
        emergencyHardCap: Decimal? = nil,
        currentBalance: Decimal
    ) {
        self.id = id
        self.name = name
        self.accountType = accountType
        self.isPrimary = isPrimary
        self.isPrimarySavings = isPrimarySavings
        self.emergencyMultiplier = emergencyMultiplier
        self.emergencyHardCap = emergencyHardCap
        self.currentBalance = currentBalance
    }

    /// Convert to Domain AccountEntry for business logic calculations.
    /// This ensures all calculations use the single source of truth in Domain.
    public func toAccountEntry() -> AccountEntry {
        AccountEntry(
            id: id,
            name: name,
            accountType: accountType,
            isPrimary: isPrimary,
            isPrimarySavings: isPrimarySavings,
            emergencyMultiplier: emergencyMultiplier,
            emergencyHardCap: emergencyHardCap,
            currentBalance: currentBalance
        )
    }

    /// Calculate emergency fund target based on income.
    /// Delegates to Domain's AccountEntry for the actual calculation.
    public func emergencyTarget(monthlyIncome: Decimal) -> Decimal? {
        toAccountEntry().emergencyTarget(monthlyIncome: monthlyIncome)
    }

    /// Progress toward emergency target (0.0-1.0).
    /// Delegates to Domain's AccountEntry for the actual calculation.
    public func emergencyProgress(monthlyIncome: Decimal) -> Double? {
        toAccountEntry().emergencyProgress(monthlyIncome: monthlyIncome)
    }
}

/// Simplified expense representation for Dashboard.
public struct DashboardExpense: Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let amount: Decimal
    public let icon: String
    public let linkedAccountId: UUID?

    public init(
        id: UUID,
        name: String,
        amount: Decimal,
        icon: String,
        linkedAccountId: UUID?
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.icon = icon
        self.linkedAccountId = linkedAccountId
    }
}

/// ViewModel for the main Dashboard view.
@Observable
@MainActor
public final class DashboardViewModel {
    // MARK: - Data State

    public var userName: String = ""
    public var monthlyIncome: Decimal = 0
    public var currency: Currency = .ron
    public var accounts: [DashboardAccount] = []
    public var expenses: [DashboardExpense] = []
    public var savingsPercentage: Double = 0.25
    public var savingsBoostEnabled: Bool = false
    public var savingsBoostMultiplier: Double = 3.0
    public var remainingMoneyDestination: RemainingMoneyDestination = .primarySavings

    // MARK: - UI State

    public var showNewMonthSheet: Bool = false
    public var currentMonthRecord: MonthlyRecord?
    public var hasCompletedOnboarding: Bool = false

    // MARK: - Init

    public init() {}

    // MARK: - Data Loading

    /// Loads data from the provider (called by the main app).
    public func loadData(from provider: DashboardDataProvider) {
        self.userName = provider.userName
        self.monthlyIncome = provider.monthlyIncome
        self.currency = provider.currency
        self.accounts = provider.accounts
        self.expenses = provider.expenses
        self.savingsPercentage = provider.savingsPercentage
        self.savingsBoostEnabled = provider.savingsBoostEnabled
        self.savingsBoostMultiplier = provider.savingsBoostMultiplier
        self.remainingMoneyDestination = provider.remainingMoneyDestination
        self.hasCompletedOnboarding = !userName.isEmpty && monthlyIncome > 0
    }

    // MARK: - Computed Properties

    /// Total of all enabled expenses.
    public var totalExpenses: Decimal {
        expenses.reduce(0) { $0 + $1.amount }
    }

    /// Income after deducting expenses.
    public var availableIncome: Decimal {
        max(0, monthlyIncome - totalExpenses)
    }

    /// Effective savings percentage after boost.
    public var effectiveSavingsPercentage: Double {
        savingsBoostEnabled ? min(1.0, savingsPercentage * savingsBoostMultiplier) : savingsPercentage
    }

    /// Total savings amount based on available income.
    public var totalSavings: Decimal {
        availableIncome * Decimal(effectiveSavingsPercentage)
    }

    /// Emergency fund account, if exists.
    public var emergencyAccount: DashboardAccount? {
        accounts.first { $0.accountType == .emergency }
    }

    /// Emergency fund progress (0.0-1.0).
    public var emergencyProgress: Double? {
        emergencyAccount?.emergencyProgress(monthlyIncome: monthlyIncome)
    }

    /// Emergency fund target amount.
    public var emergencyTarget: Decimal? {
        emergencyAccount?.emergencyTarget(monthlyIncome: monthlyIncome)
    }

    /// Primary savings account.
    public var primarySavingsAccount: DashboardAccount? {
        accounts.first { $0.isPrimarySavings }
    }

    /// Personal spending account.
    public var personalAccount: DashboardAccount? {
        accounts.first { $0.accountType == .personal }
    }

    /// Primary (checking) account.
    public var primaryAccount: DashboardAccount? {
        accounts.first { $0.isPrimary }
    }

    /// Non-primary accounts for display.
    public var displayAccounts: [DashboardAccount] {
        accounts.filter { !$0.isPrimary }
    }

    /// Current month and year for header.
    public var currentMonthDisplay: String {
        DateFormatters.monthYear.string(from: .now)
    }

    // MARK: - Transfer Plan

    /// Generates a transfer plan using the Domain calculator.
    public var transferPlan: TransferPlan {
        TransferCalculator.calculate(
            income: monthlyIncome,
            expenses: makeExpenseEntries(),
            allocation: makeSavingsAllocation(),
            accounts: makeAccountEntries(),
            remainingDestination: remainingMoneyDestination
        )
    }

    // MARK: - Actions

    public func openNewMonthFlow() {
        showNewMonthSheet = true
    }

    // MARK: - Transfer Plan Calculation

    /// Generates a transfer plan with custom income (for New Month flow).
    public func calculateTransferPlan(withIncome income: Decimal) -> TransferPlan {
        TransferCalculator.calculate(
            income: income,
            expenses: makeExpenseEntries(),
            allocation: makeSavingsAllocation(),
            accounts: makeAccountEntries(),
            remainingDestination: remainingMoneyDestination
        )
    }

    // MARK: - Private Helpers

    private func makeAccountEntries() -> [AccountEntry] {
        accounts.map { $0.toAccountEntry() }
    }

    private func makeExpenseEntries() -> [ExpenseEntry] {
        expenses.map { expense in
            ExpenseEntry(
                name: expense.name,
                amount: expense.amount,
                icon: expense.icon,
                linkedAccountId: expense.linkedAccountId
            )
        }
    }

    private func makeSavingsAllocation() -> SavingsAllocationEntry {
        SavingsAllocationEntry(
            percentage: savingsPercentage,
            boostEnabled: savingsBoostEnabled,
            boostMultiplier: savingsBoostMultiplier
        )
    }
}

// MARK: - New Month Balance Calculation

extension DashboardViewModel {
    /// Computes updated account balances after a New Month flow completion.
    /// Pure function: takes reconciled balances + transfer plan, returns new balances per account ID.
    ///
    /// Logic:
    /// 1. Start from reconciled balances (user's actual current balances from Step 2)
    /// 2. Add transfer plan allocations (emergency, savings)
    /// 3. Add expense-linked transfers (e.g., Food → Joint)
    /// 4. Add remaining money to the designated account
    /// 5. Set primary account to remainsInPrimary
    public func computeUpdatedBalances(from data: NewMonthCompletionData) -> [UUID: Decimal] {
        var balances = data.reconciledBalances
        let plan = data.transferPlan

        // Add savings allocations (emergency, savings accounts)
        for allocation in plan.accountAllocations {
            balances[allocation.accountId, default: 0] += allocation.amount
        }

        // Add expense-linked transfers (e.g., Food → Joint)
        for expenseTransfer in plan.accountExpenseTransfers {
            balances[expenseTransfer.accountId, default: 0] += expenseTransfer.amount
        }

        // Add remaining money to the designated account
        if plan.remainingMoney > 0 {
            switch plan.remainingDestination {
            case .primarySavings:
                if let savingsAccount = accounts.first(where: { $0.isPrimarySavings }) {
                    balances[savingsAccount.id, default: 0] += plan.remainingMoney
                }
            case .personal:
                if let personalAccount = accounts.first(where: { $0.accountType == .personal }) {
                    balances[personalAccount.id, default: 0] += plan.remainingMoney
                }
            case .primary:
                break
            }
        }

        // Set primary account to what stays for expenses
        if let primaryAccount = accounts.first(where: { $0.isPrimary }) {
            balances[primaryAccount.id] = plan.remainsInPrimary
        }

        return balances
    }
}

// MARK: - New Month Completion Data

/// Data passed back when completing the New Month flow.
public struct NewMonthCompletionData: Sendable {
    public let income: Decimal
    public let transferPlan: TransferPlan
    public let reconciledBalances: [UUID: Decimal]

    public init(income: Decimal, transferPlan: TransferPlan, reconciledBalances: [UUID: Decimal]) {
        self.income = income
        self.transferPlan = transferPlan
        self.reconciledBalances = reconciledBalances
    }
}
