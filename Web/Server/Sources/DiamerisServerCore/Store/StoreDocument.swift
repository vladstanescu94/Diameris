import Domain
import Foundation
import Utilities

/// The entire persisted state — one JSON document.
///
/// Deliberately a flat aggregate rather than a relational schema: this is a single-user local
/// app with one small object graph, and a second set of models (Fluent/SQLite) would duplicate
/// `Domain` for no benefit (`DECISIONS.md` D2).
///
/// Every monetary field is a `DecimalString`, so money is a string on disk as well as on the
/// wire and `1182.5` survives a restart.
public struct StoreDocument: Codable, Sendable {
    public var schemaVersion: Int
    public var profile: ProfileRecord?
    public var income: IncomeRecord?
    public var savings: SavingsRecord
    public var accounts: [AccountRecord]
    public var expenses: [ExpenseRecord]
    public var categories: [CategoryRecord]

    public static let currentSchemaVersion = 1

    public init(
        schemaVersion: Int = StoreDocument.currentSchemaVersion,
        profile: ProfileRecord? = nil,
        income: IncomeRecord? = nil,
        savings: SavingsRecord = SavingsRecord(),
        accounts: [AccountRecord] = [],
        expenses: [ExpenseRecord] = [],
        categories: [CategoryRecord] = []
    ) {
        self.schemaVersion = schemaVersion
        self.profile = profile
        self.income = income
        self.savings = savings
        self.accounts = accounts
        self.expenses = expenses
        self.categories = categories
    }

    /// Onboarding is complete exactly when iOS considers it so: a profile exists.
    /// (`MainTabView.loadDashboardData` bails out when `userProfiles.first` is nil.)
    public var onboardingCompleted: Bool { profile != nil }

    /// The currency every amount is formatted in.
    public var currency: Currency {
        profile.flatMap { Currency(rawValue: $0.currencyCode) } ?? .ron
    }

    public var monthlyIncome: Decimal { income?.amount.value ?? 0 }

    // MARK: - Seed

    /// A freshly seeded store: the 8 default categories and default savings settings, and
    /// nothing else. Accounts, expenses, profile and income all come from onboarding.
    ///
    /// Both the categories and the savings defaults are read **out of `Domain`** rather than
    /// transcribed, so there is no second copy of `DOMAIN-CONTRACT.md §6` to drift.
    public static func seeded() -> StoreDocument {
        StoreDocument(
            savings: SavingsRecord(SavingsAllocationEntry()),
            categories: Domain.Category.defaults.map(CategoryRecord.init)
        )
    }
}

// MARK: - Records

public struct ProfileRecord: Codable, Sendable {
    public var name: String
    public var currencyCode: String
    public var remainingMoneyDestinationRaw: String
    public var createdAt: Date

    public init(
        name: String,
        currencyCode: String,
        remainingMoneyDestination: RemainingMoneyDestination = .primarySavings,
        createdAt: Date = Date()
    ) {
        self.name = name
        self.currencyCode = currencyCode
        self.remainingMoneyDestinationRaw = remainingMoneyDestination.rawValue
        self.createdAt = createdAt
    }

    /// Falls back to `.primarySavings` on an unknown raw value, matching `UserProfile`.
    public var remainingMoneyDestination: RemainingMoneyDestination {
        get { RemainingMoneyDestination(rawValue: remainingMoneyDestinationRaw) ?? .primarySavings }
        set { remainingMoneyDestinationRaw = newValue.rawValue }
    }
}

public struct IncomeRecord: Codable, Sendable {
    public var id: UUID
    public var name: String
    public var amount: DecimalString
    public var frequencyRaw: String
    public var isActive: Bool
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String = "Salary",
        amount: Decimal,
        frequency: Frequency = .monthly,
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.amount = DecimalString(amount)
        self.frequencyRaw = frequency.rawValue
        self.isActive = isActive
        self.createdAt = createdAt
    }

    public var frequency: Frequency {
        Frequency(rawValue: frequencyRaw) ?? .monthly
    }
}

public struct AccountRecord: Codable, Sendable {
    public var id: UUID
    public var name: String
    public var purpose: String?
    public var accountTypeRaw: String
    public var isPrimary: Bool
    public var isPrimarySavings: Bool
    public var emergencyMultiplier: Double?
    public var emergencyHardCap: DecimalString?
    public var currentBalance: DecimalString
    public var sortOrder: Int
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        purpose: String? = nil,
        accountType: AccountType = .other,
        isPrimary: Bool = false,
        isPrimarySavings: Bool = false,
        emergencyMultiplier: Double? = nil,
        emergencyHardCap: Decimal? = nil,
        currentBalance: Decimal = 0,
        sortOrder: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.purpose = purpose
        self.accountTypeRaw = accountType.rawValue
        self.isPrimary = isPrimary
        // Normalise exactly as iOS does on save (`SettingsSheet.swift:605-607`):
        //   isPrimarySavings  = accountType == .savings  ? … : false
        //   emergencyMultiplier = accountType == .emergency ? … : nil
        // Enforced here, at the single choke point every write path goes through (onboarding,
        // POST/PUT /api/accounts, the golden-vector seeder), rather than at each caller — a
        // constraint placed on the data cannot be bypassed by a caller who forgets it (R33).
        //
        // Why it matters: iOS's Settings savings section shows when
        // `accountType == .savings || isPrimarySavings` (`SettingsSheet.swift:61-63`). An account
        // flagged isPrimarySavings while typed `.personal` is unreachable in the iOS UI but was
        // reachable through this API, producing a state iOS can never be in.
        self.isPrimarySavings = accountType == .savings ? isPrimarySavings : false
        self.emergencyMultiplier = accountType == .emergency ? emergencyMultiplier : nil
        self.emergencyHardCap = accountType == .emergency ? emergencyHardCap.map(DecimalString.init) : nil
        self.currentBalance = DecimalString(currentBalance)
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }

    /// Falls back to `.other`, matching `Persistence.Account`.
    public var accountType: AccountType {
        get { AccountType(rawValue: accountTypeRaw) ?? .other }
        set { accountTypeRaw = newValue.rawValue }
    }

    public init(_ entry: AccountEntry, sortOrder: Int) {
        self.init(
            id: entry.id,
            name: entry.name,
            purpose: entry.purpose,
            accountType: entry.accountType,
            isPrimary: entry.isPrimary,
            isPrimarySavings: entry.isPrimarySavings,
            emergencyMultiplier: entry.emergencyMultiplier,
            emergencyHardCap: entry.emergencyHardCap,
            currentBalance: entry.currentBalance,
            sortOrder: sortOrder
        )
    }

    /// The Domain value this record stands for. All calculations go through this.
    public func toEntry() -> AccountEntry {
        AccountEntry(
            id: id,
            name: name,
            purpose: purpose,
            accountType: accountType,
            isPrimary: isPrimary,
            isPrimarySavings: isPrimarySavings,
            emergencyMultiplier: emergencyMultiplier,
            emergencyHardCap: emergencyHardCap?.value,
            currentBalance: currentBalance.value
        )
    }
}

public struct ExpenseRecord: Codable, Sendable {
    public var id: UUID
    public var name: String
    public var amount: DecimalString
    public var frequencyRaw: String
    public var icon: String
    public var isEnabled: Bool
    public var linkedAccountId: UUID?
    public var categoryId: UUID?
    public var notes: String?
    public var sortOrder: Int
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        amount: Decimal,
        frequency: Frequency = .monthly,
        icon: String,
        isEnabled: Bool = true,
        linkedAccountId: UUID? = nil,
        categoryId: UUID? = nil,
        notes: String? = nil,
        sortOrder: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.amount = DecimalString(amount)
        self.frequencyRaw = frequency.rawValue
        self.icon = icon
        self.isEnabled = isEnabled
        self.linkedAccountId = linkedAccountId
        self.categoryId = categoryId
        self.notes = notes
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }

    public var frequency: Frequency {
        get { Frequency(rawValue: frequencyRaw) ?? .monthly }
        set { frequencyRaw = newValue.rawValue }
    }

    public init(_ entry: ExpenseEntry, sortOrder: Int) {
        self.init(
            id: entry.id,
            name: entry.name,
            amount: entry.amount,
            frequency: entry.frequency,
            icon: entry.icon,
            isEnabled: entry.isEnabled,
            linkedAccountId: entry.linkedAccountId,
            categoryId: entry.categoryId,
            notes: entry.notes,
            sortOrder: sortOrder
        )
    }

    public func toEntry() -> ExpenseEntry {
        ExpenseEntry(
            id: id,
            name: name,
            amount: amount.value,
            frequency: frequency,
            icon: icon,
            categoryId: categoryId,
            linkedAccountId: linkedAccountId,
            isEnabled: isEnabled,
            notes: notes
        )
    }
}

public struct CategoryRecord: Codable, Sendable {
    public var id: UUID
    public var name: String
    public var icon: String
    public var colorHex: String
    public var isDefault: Bool
    public var sortOrder: Int
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String,
        isDefault: Bool = false,
        sortOrder: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.isDefault = isDefault
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }

    public init(_ category: Domain.Category) {
        self.init(
            id: category.id,
            name: category.name,
            icon: category.icon,
            colorHex: category.colorHex,
            isDefault: category.isDefault,
            sortOrder: category.sortOrder
        )
    }

    public func toCategory() -> Domain.Category {
        Domain.Category(
            id: id,
            name: name,
            icon: icon,
            colorHex: colorHex,
            isDefault: isDefault,
            sortOrder: sortOrder
        )
    }
}

/// The savings allocation, stored with enum-raw suffixes exactly like
/// `Persistence.SavingsAllocation`, with the same property-level defaults — which is what makes
/// a document written by an older build still readable.
public struct SavingsRecord: Codable, Sendable {
    public var id: UUID = UUID()
    public var percentage: Double = 0.25
    public var boostEnabled: Bool = false
    public var boostMultiplier: Double = 3.0
    public var allocationModeRaw: String = AllocationMode.prioritized.rawValue
    public var savingsInputModeRaw: String = SavingsInputMode.percentage.rawValue
    public var fixedAmount: DecimalString = 0
    public var splitEmergencyInputModeRaw: String = SavingsInputMode.fixedAmount.rawValue
    public var splitEmergencyAmount: DecimalString = 0
    public var splitEmergencyPercentage: Double = 0.10
    public var splitSavingsInputModeRaw: String = SavingsInputMode.fixedAmount.rawValue
    public var splitSavingsAmount: DecimalString = 0
    public var splitSavingsPercentage: Double = 0.15
    public var createdAt: Date = Date()

    public init() {}

    /// Built from the Domain entry, so the defaults are Domain's, never transcribed.
    public init(_ entry: SavingsAllocationEntry) {
        self.id = entry.id
        self.percentage = entry.percentage
        self.boostEnabled = entry.boostEnabled
        self.boostMultiplier = entry.boostMultiplier
        self.allocationModeRaw = entry.allocationMode.rawValue
        self.savingsInputModeRaw = entry.savingsInputMode.rawValue
        self.fixedAmount = DecimalString(entry.fixedAmount)
        self.splitEmergencyInputModeRaw = entry.splitEmergencyInputMode.rawValue
        self.splitEmergencyAmount = DecimalString(entry.splitEmergencyAmount)
        self.splitEmergencyPercentage = entry.splitEmergencyPercentage
        self.splitSavingsInputModeRaw = entry.splitSavingsInputMode.rawValue
        self.splitSavingsAmount = DecimalString(entry.splitSavingsAmount)
        self.splitSavingsPercentage = entry.splitSavingsPercentage
    }

    // Type-safe getters with the same fallbacks as the SwiftData model.
    public var allocationMode: AllocationMode {
        get { AllocationMode(rawValue: allocationModeRaw) ?? .prioritized }
        set { allocationModeRaw = newValue.rawValue }
    }

    public var savingsInputMode: SavingsInputMode {
        get { SavingsInputMode(rawValue: savingsInputModeRaw) ?? .percentage }
        set { savingsInputModeRaw = newValue.rawValue }
    }

    public var splitEmergencyInputMode: SavingsInputMode {
        get { SavingsInputMode(rawValue: splitEmergencyInputModeRaw) ?? .fixedAmount }
        set { splitEmergencyInputModeRaw = newValue.rawValue }
    }

    public var splitSavingsInputMode: SavingsInputMode {
        get { SavingsInputMode(rawValue: splitSavingsInputModeRaw) ?? .fixedAmount }
        set { splitSavingsInputModeRaw = newValue.rawValue }
    }

    public func toEntry() -> SavingsAllocationEntry {
        SavingsAllocationEntry(
            id: id,
            percentage: percentage,
            boostEnabled: boostEnabled,
            boostMultiplier: boostMultiplier,
            allocationMode: allocationMode,
            savingsInputMode: savingsInputMode,
            fixedAmount: fixedAmount.value,
            splitEmergencyInputMode: splitEmergencyInputMode,
            splitEmergencyAmount: splitEmergencyAmount.value,
            splitEmergencyPercentage: splitEmergencyPercentage,
            splitSavingsInputMode: splitSavingsInputMode,
            splitSavingsAmount: splitSavingsAmount.value,
            splitSavingsPercentage: splitSavingsPercentage
        )
    }
}
