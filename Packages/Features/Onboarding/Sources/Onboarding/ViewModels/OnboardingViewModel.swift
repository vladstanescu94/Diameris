import Foundation
import Utilities
import Domain

@MainActor
@Observable
public final class OnboardingViewModel {
    // MARK: - Collected Data

    public var name: String = ""
    public var currency: Currency = .fromLocale()
    public var monthlyIncome: Decimal = 0

    public var expenses: [ExpenseEntry] = [
        ExpenseEntry(name: "Food".localized, amount: 0, icon: "cart.fill", categoryId: Category.foodGroceries.id),
        ExpenseEntry(name: "Rent".localized, amount: 0, icon: "house.fill", categoryId: Category.housing.id),
        ExpenseEntry(name: "Gas".localized, amount: 0, icon: "fuelpump.fill", categoryId: Category.autoTransport.id),
        ExpenseEntry(name: "Streaming".localized, amount: 0, icon: "tv.fill", categoryId: Category.subscriptions.id)
    ]

    public var accounts: [AccountEntry] = AccountEntry.defaults

    public var savingsAllocation = SavingsAllocationEntry()

    public var remainingMoneyDestination: RemainingMoneyDestination = .primarySavings

    // MARK: - Flow State

    public var currentStep: OnboardingStep = .welcome

    /// True while a step change is pending, so rapid taps can't skip a step.
    private(set) var isAdvancing = false

    /// True once the result was handed off, so a second tap before the screen changes can't save it twice.
    public private(set) var hasCompleted = false

    public enum OnboardingStep: Int, CaseIterable, Sendable {
        case welcome
        case name
        case income
        case accounts
        case expenses      // Before savings: savings are a share of income after expenses
        case savings
        case transferPlan

        var next: OnboardingStep? {
            OnboardingStep(rawValue: rawValue + 1)
        }
    }

    // MARK: - Validation Limits

    static let maximumNameLength = 50

    // MARK: - Initialization

    private let keyboardDismissDelay: Duration
    private let keyboardDismisser: @MainActor () -> Void

    /// - Parameters:
    ///   - keyboardDismissDelay: Pause between dismissing the keyboard and changing step,
    ///     so the keyboard is gone before the screen transition starts.
    ///   - keyboardDismisser: Resigns the first responder; injectable for tests.
    public init(
        keyboardDismissDelay: Duration = .milliseconds(150),
        keyboardDismisser: @escaping @MainActor () -> Void = { KeyboardHelper.dismiss() }
    ) {
        self.keyboardDismissDelay = keyboardDismissDelay
        self.keyboardDismisser = keyboardDismisser
    }

    // MARK: - Navigation

    /// Moves to the next step when the current one is valid.
    /// Ignored while a previous advance is still pending (double taps, submit + button).
    /// - Returns: The pending transition, so callers can await it.
    @discardableResult
    public func advance() -> Task<Void, Never>? {
        guard canAdvance, !isAdvancing, let next = currentStep.next else { return nil }
        isAdvancing = true
        dismissKeyboard()
        return Task {
            try? await Task.sleep(for: keyboardDismissDelay)
            if next == .transferPlan {
                resolveRemainingMoneyDestination()
            }
            currentStep = next
            isAdvancing = false
        }
    }

    public func dismissKeyboard() {
        keyboardDismisser()
    }

    public var canAdvance: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .name:
            return (1...Self.maximumNameLength).contains(trimmedName.count)
        case .income:
            return monthlyIncome > 0
        case .accounts:
            return accounts.contains { $0.isPrimary }
        case .savings:
            return true
        case .expenses:
            return true
        case .transferPlan:
            return true
        }
    }

    public var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Computed Properties

    public var primaryAccount: AccountEntry? {
        accounts.first { $0.isPrimary }
    }

    public var emergencyAccount: AccountEntry? {
        accounts.first { $0.accountType == .emergency }
    }

    public var primarySavingsAccount: AccountEntry? {
        accounts.first { $0.isPrimarySavings }
    }

    public var personalAccount: AccountEntry? {
        accounts.first { $0.accountType == .personal }
    }

    public var hasEmergencyAccount: Bool {
        emergencyAccount != nil
    }

    public var hasPrimarySavingsAccount: Bool {
        primarySavingsAccount != nil
    }

    public var transferPlan: TransferPlan {
        TransferCalculator.calculate(
            income: monthlyIncome,
            expenses: expenses,
            allocation: savingsAllocation,
            accounts: accounts,
            remainingDestination: remainingMoneyDestination
        )
    }

    /// Income left after expenses — the base savings are calculated from.
    public var availableIncome: Decimal {
        transferPlan.availableIncome
    }

    // MARK: - Savings

    /// Whether boosting the current rate stays within available income (e.g. 3× only up to 33%).
    public var canEnableBoost: Bool {
        savingsAllocation.canEnableBoost
    }

    /// Boost toggle state. Turning it on is ignored when it would exceed available income.
    public var isBoostEnabled: Bool {
        get { savingsAllocation.boostEnabled }
        set {
            guard !newValue || canEnableBoost else { return }
            savingsAllocation.boostEnabled = newValue
        }
    }

    /// Turns boost off if the savings rate was raised past the safe threshold.
    public func disableBoostIfUnsafe() {
        if savingsAllocation.boostEnabled && !canEnableBoost {
            savingsAllocation.boostEnabled = false
        }
    }

    // MARK: - Remaining Money

    /// Destinations that name an account the user actually has.
    public var availableRemainingDestinations: [RemainingMoneyDestination] {
        accounts.availableRemainingDestinations
    }

    func resolveRemainingMoneyDestination() {
        remainingMoneyDestination = accounts.resolvedRemainingDestination(remainingMoneyDestination)
    }

    // MARK: - Account Rules

    /// Types a non-primary account may switch to. The primary role is fixed to the first account.
    public static let assignableAccountTypes = AccountType.allCases.filter { $0 != .primary }

    /// Whether `type` can be given to the account with `id` without breaking uniqueness rules.
    public func canAssign(_ type: AccountType, toAccount id: UUID?) -> Bool {
        accounts.canAssign(type, toAccount: id)
    }

    /// Adds an account from the Add Account sheet. Returns false when the type isn't allowed.
    @discardableResult
    public func addAccount(name: String, type: AccountType) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, canAssign(type, toAccount: nil) else { return false }

        var account = AccountEntry(name: trimmed, accountType: type)
        applyTypeDefaults(to: &account)
        accounts.append(account)
        return true
    }

    public func addEmergencyAccount() {
        guard canAssign(.emergency, toAccount: nil) else { return }
        accounts.append(.emergency())
    }

    public func addSavingsAccount() {
        guard !hasPrimarySavingsAccount else { return }
        accounts.append(.savings(isPrimarySavings: true))
    }

    /// Removes a non-primary account, unlinking its expenses and handing the
    /// auto-save role to another savings account if it held it.
    public func deleteAccount(id: UUID) {
        guard let index = accounts.firstIndex(where: { $0.id == id }),
              !accounts[index].isPrimary else { return }
        let removed = accounts.remove(at: index)

        for expenseIndex in expenses.indices where expenses[expenseIndex].linkedAccountId == id {
            expenses[expenseIndex].linkedAccountId = nil
        }
        if removed.isPrimarySavings {
            promoteFallbackPrimarySavings()
        }
    }

    public func changeAccountType(id: UUID, to type: AccountType) {
        guard let index = accounts.firstIndex(where: { $0.id == id }),
              !accounts[index].isPrimary,
              accounts[index].accountType != type,
              canAssign(type, toAccount: id) else { return }

        // Edited as a copy: applyTypeDefaults reads `accounts`, which an in-place
        // `&accounts[index]` access would still be modifying (a runtime exclusivity trap).
        var account = accounts[index]
        let wasPrimarySavings = account.isPrimarySavings
        account.accountType = type
        account.isPrimarySavings = false
        account.emergencyMultiplier = nil
        account.emergencyHardCap = nil
        applyTypeDefaults(to: &account)
        accounts[index] = account

        if wasPrimarySavings && !account.isPrimarySavings {
            promoteFallbackPrimarySavings()
        }
    }

    /// Makes a savings account the one that receives automatic savings.
    public func setPrimarySavings(id: UUID) {
        guard accounts.contains(where: { $0.id == id && $0.accountType == .savings }) else { return }
        for index in accounts.indices {
            accounts[index].isPrimarySavings = accounts[index].id == id
        }
    }

    /// Renames an account; blank names are ignored.
    public func renameAccount(id: UUID, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        updateAccount(id: id) { $0.name = trimmed }
    }

    /// Edits free-form account fields (balance, emergency multiplier, hard cap).
    public func updateAccount(id: UUID, _ update: (inout AccountEntry) -> Void) {
        guard let index = accounts.firstIndex(where: { $0.id == id }) else { return }
        // Via a copy, so an `update` closure that reads the view model can't trap (see changeAccountType).
        var account = accounts[index]
        update(&account)
        accounts[index] = account
    }

    private func applyTypeDefaults(to account: inout AccountEntry) {
        switch account.accountType {
        case .emergency:
            account.emergencyMultiplier = AccountEntry.emergency().emergencyMultiplier
        case .savings:
            account.isPrimarySavings = !hasPrimarySavingsAccount
        default:
            break
        }
    }

    private func promoteFallbackPrimarySavings() {
        guard !hasPrimarySavingsAccount,
              let index = accounts.firstIndex(where: { $0.accountType == .savings }) else { return }
        accounts[index].isPrimarySavings = true
    }

    // MARK: - Result

    /// The result to save, or nil when it was already handed off.
    public func complete() -> OnboardingResult? {
        guard !hasCompleted else { return nil }
        hasCompleted = true
        return makeResult()
    }

    /// Re-arms Start after the app couldn't save the result, so the user can retry.
    public func completionFailed() {
        hasCompleted = false
    }

    /// Balances assume the user made this month's transfers, computed by the same
    /// `BalanceReconciler` New Month uses.
    public func makeResult() -> OnboardingResult {
        let balances = BalanceReconciler.updatedBalances(
            plan: transferPlan,
            accounts: accounts,
            reconciledBalances: [:]
        )
        let finalAccounts = accounts.map { account in
            var account = account
            account.currentBalance = balances[account.id] ?? account.currentBalance
            return account
        }

        return OnboardingResult(
            name: trimmedName,
            currencyCode: currency.rawValue,
            incomeName: "Salary".localized,
            monthlyIncome: monthlyIncome,
            expenses: expenses.filter { $0.amount > 0 },
            accounts: finalAccounts,
            savingsAllocation: savingsAllocation,
            remainingMoneyDestination: remainingMoneyDestination
        )
    }
}
