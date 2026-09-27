import Foundation
import Observation
import Domain
import Utilities

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
    var allocationMode: AllocationMode { get }
    var savingsInputMode: SavingsInputMode { get }
    var savingsFixedAmount: Decimal { get }
    var splitEmergencyInputMode: SavingsInputMode { get }
    var splitEmergencyAmount: Decimal { get }
    var splitEmergencyPercentage: Double { get }
    var splitSavingsInputMode: SavingsInputMode { get }
    var splitSavingsAmount: Decimal { get }
    var splitSavingsPercentage: Double { get }
}

/// Calculations delegate to Domain's `AccountEntry`.
public struct DashboardAccount: Identifiable, Equatable, Sendable {
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

    public func emergencyTarget(monthlyIncome: Decimal) -> Decimal? {
        toAccountEntry().emergencyTarget(monthlyIncome: monthlyIncome)
    }

    /// Progress toward emergency target (0.0-1.0).
    public func emergencyProgress(monthlyIncome: Decimal) -> Double? {
        toAccountEntry().emergencyProgress(monthlyIncome: monthlyIncome)
    }
}

public struct DashboardExpense: Identifiable, Equatable, Sendable {
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

    /// `amount` is already the monthly equivalent, so the entry is monthly.
    public func toExpenseEntry() -> ExpenseEntry {
        ExpenseEntry(name: name, amount: amount, icon: icon, linkedAccountId: linkedAccountId)
    }
}

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
    public var allocationMode: AllocationMode = .prioritized
    public var savingsInputMode: SavingsInputMode = .percentage
    public var savingsFixedAmount: Decimal = 0
    public var splitEmergencyInputMode: SavingsInputMode = .fixedAmount
    public var splitEmergencyAmount: Decimal = 0
    public var splitEmergencyPercentage: Double = 0.10
    public var splitSavingsInputMode: SavingsInputMode = .fixedAmount
    public var splitSavingsAmount: Decimal = 0
    public var splitSavingsPercentage: Double = 0.15

    // MARK: - UI State

    public var showNewMonthSheet: Bool = false
    public var hasCompletedOnboarding: Bool = false

    // MARK: - Init

    public init() {}

    // MARK: - Data Loading

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
        self.allocationMode = provider.allocationMode
        self.savingsInputMode = provider.savingsInputMode
        self.savingsFixedAmount = provider.savingsFixedAmount
        self.splitEmergencyInputMode = provider.splitEmergencyInputMode
        self.splitEmergencyAmount = provider.splitEmergencyAmount
        self.splitEmergencyPercentage = provider.splitEmergencyPercentage
        self.splitSavingsInputMode = provider.splitSavingsInputMode
        self.splitSavingsAmount = provider.splitSavingsAmount
        self.splitSavingsPercentage = provider.splitSavingsPercentage
        self.hasCompletedOnboarding = !userName.isEmpty && monthlyIncome > 0
    }

    // MARK: - Computed Properties
    // Totals, available income and savings come from `transferPlan` (Domain's TransferCalculator)
    // so the Dashboard never re-derives budget math. Views should read the plan once per body.

    public var emergencyAccount: DashboardAccount? {
        accounts.first { $0.accountType == .emergency }
    }

    /// Emergency fund progress (0.0-1.0).
    public var emergencyProgress: Double? {
        emergencyAccount?.emergencyProgress(monthlyIncome: monthlyIncome)
    }

    public var emergencyTarget: Decimal? {
        emergencyAccount?.emergencyTarget(monthlyIncome: monthlyIncome)
    }

    public var savingsAllocation: SavingsAllocationEntry {
        makeSavingsAllocation()
    }

    public var currentMonthDisplay: String {
        DateFormatters.monthYear.string(from: .now)
    }

    // MARK: - Transfer Plan

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

    /// Optionally overrides each account's current balance with reconciled balances
    /// from the New Month flow's account-reconciliation step.
    /// `boostEnabled` overrides the stored boost choice for this plan only.
    public func calculateTransferPlan(
        withIncome income: Decimal,
        reconciledBalances: [UUID: Decimal] = [:],
        boostEnabled: Bool? = nil
    ) -> TransferPlan {
        var allocation = makeSavingsAllocation()
        if let boostEnabled {
            allocation.boostEnabled = boostEnabled
        }
        return TransferCalculator.calculate(
            income: income,
            expenses: makeExpenseEntries(),
            allocation: allocation,
            accounts: makeAccountEntries(reconciledBalances: reconciledBalances),
            remainingDestination: remainingMoneyDestination
        )
    }

    // MARK: - Private Helpers

    private func makeAccountEntries(reconciledBalances: [UUID: Decimal] = [:]) -> [AccountEntry] {
        accounts.map { account in
            var entry = account.toAccountEntry()
            if let reconciled = reconciledBalances[account.id] {
                entry.currentBalance = reconciled
            }
            return entry
        }
    }

    private func makeExpenseEntries() -> [ExpenseEntry] {
        expenses.map { $0.toExpenseEntry() }
    }

    private func makeSavingsAllocation() -> SavingsAllocationEntry {
        SavingsAllocationEntry(
            percentage: savingsPercentage,
            boostEnabled: savingsBoostEnabled,
            boostMultiplier: savingsBoostMultiplier,
            allocationMode: allocationMode,
            savingsInputMode: savingsInputMode,
            fixedAmount: savingsFixedAmount,
            splitEmergencyInputMode: splitEmergencyInputMode,
            splitEmergencyAmount: splitEmergencyAmount,
            splitEmergencyPercentage: splitEmergencyPercentage,
            splitSavingsInputMode: splitSavingsInputMode,
            splitSavingsAmount: splitSavingsAmount,
            splitSavingsPercentage: splitSavingsPercentage
        )
    }
}

// MARK: - New Month Balance Calculation

extension DashboardViewModel {
    /// Balances after the New Month transfers are made; delegates to `Domain.BalanceReconciler`.
    public func computeUpdatedBalances(from data: NewMonthCompletionData) -> [UUID: Decimal] {
        BalanceReconciler.updatedBalances(
            plan: data.transferPlan,
            accounts: makeAccountEntries(),
            reconciledBalances: data.reconciledBalances
        )
    }
}

// MARK: - New Month Completion Data

public struct NewMonthCompletionData: Sendable {
    public let income: Decimal
    public let transferPlan: TransferPlan
    public let reconciledBalances: [UUID: Decimal]
    /// The boost choice made in the flow; nil when the flow didn't offer one.
    public let savingsBoostEnabled: Bool?

    public init(
        income: Decimal,
        transferPlan: TransferPlan,
        reconciledBalances: [UUID: Decimal],
        savingsBoostEnabled: Bool? = nil
    ) {
        self.income = income
        self.transferPlan = transferPlan
        self.reconciledBalances = reconciledBalances
        self.savingsBoostEnabled = savingsBoostEnabled
    }
}
