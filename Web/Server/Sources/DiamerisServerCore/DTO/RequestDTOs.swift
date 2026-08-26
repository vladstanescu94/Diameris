import Domain
import Foundation
import Vapor

// Request shapes. Money arrives as `DecimalString` (a JSON string), never a number.
// Optionality here means "not supplied" — `PUT`s are partial updates.

public struct OnboardingPayload: Content, Sendable {
    public var name: String
    public var currencyCode: String?
    public var monthlyIncome: DecimalString
    public var accounts: [AccountPayload]
    public var expenses: [ExpensePayload]
    public var savings: SavingsPayload?
    public var remainingMoneyDestination: RemainingMoneyDestination?

    public struct AccountPayload: Content, Sendable {
        public var id: UUID?
        public var name: String
        public var purpose: String?
        public var accountType: AccountType?
        public var isPrimary: Bool?
        public var isPrimarySavings: Bool?
        public var emergencyMultiplier: Double?
        public var emergencyHardCap: DecimalString?
        public var currentBalance: DecimalString?

        public func toEntry() -> AccountEntry {
            AccountEntry(
                id: id ?? UUID(),
                name: name,
                purpose: purpose,
                accountType: accountType ?? .other,
                isPrimary: isPrimary ?? false,
                isPrimarySavings: isPrimarySavings ?? false,
                emergencyMultiplier: emergencyMultiplier,
                emergencyHardCap: emergencyHardCap?.value,
                currentBalance: currentBalance?.value ?? 0
            )
        }
    }

    public struct ExpensePayload: Content, Sendable {
        public var id: UUID?
        public var name: String
        public var amount: DecimalString
        public var frequency: Frequency?
        public var icon: String?
        public var categoryId: UUID?
        public var linkedAccountId: UUID?
        public var isEnabled: Bool?
        public var notes: String?

        public func toEntry() -> ExpenseEntry {
            ExpenseEntry(
                id: id ?? UUID(),
                name: name,
                amount: amount.value,
                frequency: frequency ?? .monthly,
                icon: icon ?? Defaults.expenseIcon,
                categoryId: categoryId,
                linkedAccountId: linkedAccountId,
                isEnabled: isEnabled ?? true,
                notes: notes
            )
        }
    }
}

/// All fields optional; each falls back to the Domain default so a partial payload still
/// produces the exact `SavingsAllocationEntry()` iOS would have made.
public struct SavingsPayload: Content, Sendable {
    public var percentage: Double?
    public var boostEnabled: Bool?
    public var boostMultiplier: Double?
    public var allocationMode: AllocationMode?
    public var savingsInputMode: SavingsInputMode?
    public var fixedAmount: DecimalString?
    public var splitEmergencyInputMode: SavingsInputMode?
    public var splitEmergencyAmount: DecimalString?
    public var splitEmergencyPercentage: Double?
    public var splitSavingsInputMode: SavingsInputMode?
    public var splitSavingsAmount: DecimalString?
    public var splitSavingsPercentage: Double?

    /// Applies only the supplied fields onto an existing record.
    public func apply(to record: inout SavingsRecord) {
        if let percentage { record.percentage = percentage }
        if let boostEnabled { record.boostEnabled = boostEnabled }
        if let boostMultiplier { record.boostMultiplier = boostMultiplier }
        if let allocationMode { record.allocationMode = allocationMode }
        if let savingsInputMode { record.savingsInputMode = savingsInputMode }
        if let fixedAmount { record.fixedAmount = fixedAmount }
        if let splitEmergencyInputMode { record.splitEmergencyInputMode = splitEmergencyInputMode }
        if let splitEmergencyAmount { record.splitEmergencyAmount = splitEmergencyAmount }
        if let splitEmergencyPercentage { record.splitEmergencyPercentage = splitEmergencyPercentage }
        if let splitSavingsInputMode { record.splitSavingsInputMode = splitSavingsInputMode }
        if let splitSavingsAmount { record.splitSavingsAmount = splitSavingsAmount }
        if let splitSavingsPercentage { record.splitSavingsPercentage = splitSavingsPercentage }
    }

    /// A record built from Domain defaults with the supplied fields applied on top.
    public func toRecord() -> SavingsRecord {
        var record = SavingsRecord(SavingsAllocationEntry())
        apply(to: &record)
        return record
    }
}

public struct SettingsUpdatePayload: Content, Sendable {
    public var name: String?
    public var currencyCode: String?
    public var monthlyIncome: DecimalString?
    public var remainingMoneyDestination: RemainingMoneyDestination?
    public var savings: SavingsPayload?
}

public struct AccountUpdatePayload: Content, Sendable {
    public var name: String?
    public var purpose: String?
    public var accountType: AccountType?
    public var isPrimary: Bool?
    public var isPrimarySavings: Bool?
    public var emergencyMultiplier: Double?
    public var emergencyHardCap: DecimalString?
    public var currentBalance: DecimalString?
    public var sortOrder: Int?
}

public struct ExpenseUpdatePayload: Content, Sendable {
    public var name: String?
    public var amount: DecimalString?
    public var frequency: Frequency?
    public var icon: String?
    public var categoryId: UUID?
    public var linkedAccountId: UUID?
    public var isEnabled: Bool?
    public var notes: String?
    public var sortOrder: Int?

    /// Distinguishes "field absent" from "field explicitly null" for the two nullable ids, so
    /// `{"linkedAccountId": null}` can genuinely mean "pay from primary" rather than "no change".
    public var clearsCategory: Bool = false
    public var clearsLinkedAccount: Bool = false

    enum CodingKeys: String, CodingKey {
        case name, amount, frequency, icon, categoryId, linkedAccountId, isEnabled, notes, sortOrder
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        amount = try container.decodeIfPresent(DecimalString.self, forKey: .amount)
        frequency = try container.decodeIfPresent(Frequency.self, forKey: .frequency)
        icon = try container.decodeIfPresent(String.self, forKey: .icon)
        categoryId = try container.decodeIfPresent(UUID.self, forKey: .categoryId)
        linkedAccountId = try container.decodeIfPresent(UUID.self, forKey: .linkedAccountId)
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder)
        clearsCategory = container.contains(.categoryId) && categoryId == nil
        clearsLinkedAccount = container.contains(.linkedAccountId) && linkedAccountId == nil
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(amount, forKey: .amount)
        try container.encodeIfPresent(frequency, forKey: .frequency)
        try container.encodeIfPresent(icon, forKey: .icon)
        try container.encodeIfPresent(categoryId, forKey: .categoryId)
        try container.encodeIfPresent(linkedAccountId, forKey: .linkedAccountId)
        try container.encodeIfPresent(isEnabled, forKey: .isEnabled)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(sortOrder, forKey: .sortOrder)
    }
}

public struct ExpenseCreatePayload: Content, Sendable {
    public var name: String
    public var amount: DecimalString
    public var frequency: Frequency?
    public var icon: String?
    public var categoryId: UUID?
    public var linkedAccountId: UUID?
    public var isEnabled: Bool?
    public var notes: String?
}

public struct AccountCreatePayload: Content, Sendable {
    public var id: UUID?
    public var name: String
    public var purpose: String?
    public var accountType: AccountType?
    public var isPrimary: Bool?
    public var isPrimarySavings: Bool?
    public var emergencyMultiplier: Double?
    public var emergencyHardCap: DecimalString?
    public var currentBalance: DecimalString?
}

public struct CategoryCreatePayload: Content, Sendable {
    public var id: UUID?
    public var name: String
    public var icon: String
    public var colorHex: String
    public var sortOrder: Int?
}

public struct NewMonthPayload: Content, Sendable {
    public var income: DecimalString
    /// Account id → balance. Keys are UUID strings; absent accounts keep their stored balance.
    public var reconciledBalances: [String: DecimalString]?

    public func balances() -> [UUID: Decimal] {
        var result: [UUID: Decimal] = [:]
        for (key, value) in reconciledBalances ?? [:] {
            if let id = UUID(uuidString: key) {
                result[id] = value.value
            }
        }
        return result
    }
}

/// The subset of an expense draft the preview needs.
public struct ExpensePreviewPayload: Content, Sendable {
    public var amount: DecimalString
    public var frequency: Frequency?
}

public struct ParseAmountPayload: Content, Sendable {
    public var text: String
}

/// Defaults that live in feature code on iOS rather than Domain, transcribed once here with
/// their source noted so there is a single place to check them.
public enum Defaults {
    /// `ExpensesViewModel.swift:120`
    public static let expenseIcon = "dollarsign.circle.fill"
    /// `CategoryManagementView.swift:117-118`
    public static let newCategoryIcon = "star.fill"
    public static let newCategoryColorHex = "#3B82F6"
    /// `Category.custom(sortOrder:)`
    public static let newCategorySortOrder = 100
    /// `AccountEntry.emergency(multiplier:)`
    public static let emergencyMultiplier: Double = 3.0

    /// Sentinel group id for expenses with no category (`PARITY-SPEC.md §5.2` step 4).
    public static let uncategorizedGroupId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    /// Rendered for both the uncategorized group and a dangling-category group
    /// (`ExpenseCategoryCard` falls back to this label plus a grey `questionmark.circle.fill`).
    public static let uncategorizedName = "Uncategorized"

    /// The Add Expense sheet's icon grid, in render order — **37 entries**, transcribed from
    /// `AddExpenseSheet.swift:193-231`. (`GROUND-TRUTH.md` said 18; that came from a clipped
    /// screenshot. `creditcard.fill` is the 18th, which is where the count was cut off.)
    public static let expenseIcons = [
        "dollarsign.circle.fill", "cart.fill", "house.fill", "car.fill", "fuelpump.fill",
        "shield.fill", "heart.fill", "fork.knife", "cup.and.saucer.fill", "tshirt.fill",
        "pawprint.fill", "tv.fill", "gamecontroller.fill", "music.note", "film.fill",
        "airplane", "gift.fill", "creditcard.fill", "phone.fill", "wifi",
        "bolt.fill", "drop.fill", "leaf.fill", "wrench.fill", "hammer.fill",
        "paintbrush.fill", "bandage.fill", "pills.fill", "dumbbell.fill", "bicycle",
        "bus.fill", "train.side.front.car", "book.fill", "graduationcap.fill", "briefcase.fill",
        "building.2.fill", "sparkles"
    ]

    /// The **New Category** icon grid — 12 entries, `CategoryManagementView.swift:133-137`.
    /// A different set from `expenseIcons`: they overlap on only 5 symbols, and `calendar` is
    /// here but not there. Sharing one array would silently break one of the two screens.
    public static let categoryIcons = [
        "star.fill", "heart.fill", "bolt.fill", "leaf.fill",
        "gift.fill", "tag.fill", "bookmark.fill", "flag.fill",
        "bell.fill", "clock.fill", "calendar", "folder.fill"
    ]

    /// The New Category colour swatches — 10 entries, `CategoryManagementView.swift:120-131`.
    public static let categoryColors = [
        "#3B82F6", "#8B5CF6", "#F59E0B", "#10B981", "#EC4899",
        "#EF4444", "#22C55E", "#06B6D4", "#F97316", "#6366F1"
    ]

    /// The three "Quick suggestions" chips on Add Account (`AddAccountSheet.swift:61-73`).
    ///
    /// ⚠️ Two faithfully-reproduced iOS bugs here: the chip labelled **"Emergency" creates a
    /// `.savings` account**, not an emergency one; and all three titles are raw English literals
    /// with no `.localized`, so they render in English even in Romanian. Both logged in
    /// `PARITY-GAPS.md`. Served as data so they are trivially flippable if ever fixed upstream.
    public static let accountSuggestions: [(title: String, type: AccountType)] = [
        ("Joint", .joint),
        ("Emergency", .savings),
        ("Travel", .savings)
    ]
}
