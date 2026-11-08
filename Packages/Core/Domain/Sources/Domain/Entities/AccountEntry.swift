import Foundation

/// A bank account as the transfer calculator sees it (Persistence's `Account` maps to this).
public struct AccountEntry: Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var purpose: String?
    public var accountType: AccountType
    public var isPrimary: Bool

    // MARK: - New Behavioral Properties

    /// For savings-type accounts: marks this as the primary savings account
    /// that receives automatic savings allocation.
    public var isPrimarySavings: Bool

    /// For emergency-type accounts: income multiplier for target calculation (3.0-6.0).
    /// Target = monthlyIncome × emergencyMultiplier
    public var emergencyMultiplier: Double?

    /// For emergency-type accounts: optional hard cap on the target amount.
    /// When set, target = min(monthlyIncome × emergencyMultiplier, emergencyHardCap)
    public var emergencyHardCap: Decimal?

    public var currentBalance: Decimal

    public init(
        id: UUID = UUID(),
        name: String,
        purpose: String? = nil,
        accountType: AccountType = .other,
        isPrimary: Bool = false,
        isPrimarySavings: Bool = false,
        emergencyMultiplier: Double? = nil,
        emergencyHardCap: Decimal? = nil,
        currentBalance: Decimal = 0
    ) {
        self.id = id
        self.name = name
        self.purpose = purpose
        self.accountType = accountType
        self.isPrimary = isPrimary
        self.isPrimarySavings = isPrimarySavings
        self.emergencyMultiplier = emergencyMultiplier
        self.emergencyHardCap = emergencyHardCap
        self.currentBalance = currentBalance
    }

    // MARK: - Computed Properties

    /// `uncappedEmergencyTarget`, limited by `emergencyHardCap` when one is set.
    public func emergencyTarget(monthlyIncome: Decimal) -> Decimal? {
        guard let calculatedTarget = uncappedEmergencyTarget(monthlyIncome: monthlyIncome) else {
            return nil
        }
        if let hardCap = emergencyHardCap {
            return min(calculatedTarget, hardCap)
        }
        return calculatedTarget
    }

    /// `monthlyIncome × emergencyMultiplier`, ignoring any hard cap (e.g. to show "capped at X
    /// of Y"). Returns nil if this is not an emergency account or has no multiplier.
    public func uncappedEmergencyTarget(monthlyIncome: Decimal) -> Decimal? {
        guard accountType == .emergency, let multiplier = emergencyMultiplier else {
            return nil
        }
        return (monthlyIncome * Decimal(rate: multiplier)).roundedToCents
    }

    /// Progress percentage toward emergency target (0.0 to 1.0).
    /// Returns nil if not an emergency account or target is 0.
    public func emergencyProgress(monthlyIncome: Decimal) -> Double? {
        guard let target = emergencyTarget(monthlyIncome: monthlyIncome), target > 0 else {
            return nil
        }
        let progress = (currentBalance / target).doubleValue
        return min(1.0, max(0.0, progress))
    }

    public func isEmergencyComplete(monthlyIncome: Decimal) -> Bool {
        guard let target = emergencyTarget(monthlyIncome: monthlyIncome) else {
            return false
        }
        return currentBalance >= target
    }
}

// MARK: - Smart Default Accounts

extension AccountEntry {
    public static func primary(name: String? = nil) -> AccountEntry {
        AccountEntry(
            name: name ?? "Main Account".localized,
            purpose: "Where your salary lands".localized,
            accountType: .primary,
            isPrimary: true
        )
    }

    public static func emergency(
        name: String? = nil,
        multiplier: Double = 3.0,
        hardCap: Decimal? = nil,
        currentBalance: Decimal = 0
    ) -> AccountEntry {
        AccountEntry(
            name: name ?? "Emergency Fund".localized,
            purpose: "Protects you from unexpected expenses".localized,
            accountType: .emergency,
            emergencyMultiplier: multiplier,
            emergencyHardCap: hardCap,
            currentBalance: currentBalance
        )
    }

    public static func savings(name: String? = nil, isPrimarySavings: Bool = true) -> AccountEntry {
        AccountEntry(
            name: name ?? "Savings".localized,
            purpose: "For building wealth over time".localized,
            accountType: .savings,
            isPrimarySavings: isPrimarySavings
        )
    }

    public static func personal(name: String? = nil) -> AccountEntry {
        AccountEntry(
            name: name ?? "Personal".localized,
            purpose: "Your flexible spending money".localized,
            accountType: .personal
        )
    }

    public static func joint(name: String? = nil) -> AccountEntry {
        AccountEntry(
            name: name ?? "Joint".localized,
            purpose: "For shared expenses".localized,
            accountType: .joint
        )
    }

    /// Onboarding starts with only the primary account; the user adds the rest.
    public static var defaults: [AccountEntry] {
        [.primary()]
    }
}

// MARK: - Account Roles

extension Array where Element == AccountEntry {
    /// The account that fills first with savings.
    var emergencyAccount: AccountEntry? {
        first { $0.accountType == .emergency }
    }

    /// The account that receives savings (and "Primary Savings" remaining money): the flagged
    /// primary savings account, else the first savings-type account. Never the emergency account,
    /// so a plan cannot allocate to the same account twice.
    var savingsDestination: AccountEntry? {
        first { $0.isPrimarySavings && $0.accountType != .emergency }
            ?? first { $0.accountType == .savings }
    }

    /// Remaining-money destinations backed by an account the user has. `.primary` always is.
    public var availableRemainingDestinations: [RemainingMoneyDestination] {
        var destinations: [RemainingMoneyDestination] = []
        if savingsDestination != nil { destinations.append(.primarySavings) }
        destinations.append(.primary)
        if contains(where: { $0.accountType == .personal }) { destinations.append(.personal) }
        return destinations
    }

    /// `destination` if an account fills it, otherwise `.primary`, so leftover money is never
    /// routed to an account that doesn't exist.
    public func resolvedRemainingDestination(_ destination: RemainingMoneyDestination) -> RemainingMoneyDestination {
        availableRemainingDestinations.contains(destination) ? destination : .primary
    }

    /// Whether the account with `id` (nil for a new account) may take `type`. The primary role
    /// is fixed to the primary account, and unique types can't be duplicated.
    public func canAssign(_ type: AccountType, toAccount id: UUID?) -> Bool {
        if let id, first(where: { $0.id == id })?.isPrimary == true {
            return type == .primary
        }
        guard type != .primary else { return false }
        guard type.isUnique else { return true }
        return !contains { $0.accountType == type && $0.id != id }
    }
}

// MARK: - Decimal Extension

private extension Decimal {
    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }
}
