import Domain
import Foundation
import Vapor

// Response shapes. These are pure data holders — every number in them was computed by `Domain`
// and every string formatted by `Utilities`. Nothing here calculates anything.

public struct AppStateResponse: Content, Sendable {
    public let schemaVersion: Int
    public let onboardingCompleted: Bool
    public let profile: ProfileDTO?
    public let settings: SettingsDTO
    public let accounts: [AccountDTO]
    public let expenses: [ExpenseDTO]
    public let categories: [CategoryDTO]
    public let dashboard: DashboardDTO
    public let expensesScreen: ExpensesScreenDTO
    public let transferPlan: TransferPlanDTO
    public let reference: ReferenceDTO
}

public struct ProfileDTO: Content, Sendable {
    public let name: String
    public let currencyCode: String
    public let currencyDisplayName: String
    public let remainingMoneyDestination: String
    public let remainingMoneyDestinationDisplayName: String
    public let createdAt: Date
}

public struct SettingsDTO: Content, Sendable {
    public let income: Money
    public let savings: SavingsDTO
}

public struct SavingsDTO: Content, Sendable {
    public let percentage: Double
    public let percentageDisplay: String
    public let effectivePercentage: Double
    public let effectivePercentageDisplay: String
    public let boostEnabled: Bool
    public let boostMultiplier: Double
    public let isBoostApplicable: Bool
    public let allocationMode: String
    public let allocationModeDisplayName: String
    public let allocationModeDescription: String
    public let savingsInputMode: String
    public let fixedAmount: Money
    public let splitEmergencyInputMode: String
    public let splitEmergencyAmount: Money
    public let splitEmergencyPercentage: Double
    public let splitSavingsInputMode: String
    public let splitSavingsAmount: Money
    public let splitSavingsPercentage: Double
    public let isValid: Bool
    /// `SettingsSheet.swift:218`'s "Effective Rate" row: `Int(min(100, pct * mult * 100))`.
    /// Clamps *after* multiplying where Domain clamps *before*; numerically identical today, but
    /// served so there is only one implementation of the rule.
    ///
    /// **Always present**, even when boost is off — it is the value the row *would* show. The
    /// client renders the row only when `boostEnabled`, exactly as `SettingsSheet` does.
    public let boostedPercentDisplay: String
    /// Every reachable main-slider position, resolved (R13/R18.4).
    public let savingsSliderPositions: [SliderPositionDTO]
    /// Every reachable split-side slider position, resolved. Shared by both sides — the value is
    /// `availableIncome × percentage`, which is what each side's caption renders.
    public let splitSliderPositions: [SliderPositionDTO]
    /// Split mode fully resolved (R18.1).
    public let split: SplitAllocationDTO
}

public struct AccountDTO: Content, Sendable {
    public let id: UUID
    public let name: String
    public let purpose: String?
    public let accountType: String
    public let accountTypeDisplayName: String
    public let accountTypeDescription: String
    public let icon: String
    public let isPrimary: Bool
    public let isPrimarySavings: Bool
    public let emergencyMultiplier: Double?
    public let emergencyHardCap: Money?
    public let currentBalance: Money
    public let sortOrder: Int
    public let emergencyTarget: Money?
    public let emergencyProgress: Double?
    public let emergencyProgressPercent: Int?
    public let emergencyProgressDisplay: String?
    public let isEmergencyComplete: Bool
    /// The Settings > Accounts row subtitle as **2–3 separately-coloured parts** (R23/R27).
    ///
    /// `SettingsSheet.swift:373-388` is an `HStack(spacing: Spacing.xs)` — an 8pt layout gap —
    /// holding 2–3 independent `Text` views, each with its own colour. It was never one string, so
    /// no joined form is served: splitting on `"•"` client-side would be presentation logic
    /// guessing at server data. Render these inline with an 8px gap.
    public let subtitleParts: [SubtitlePartDTO]
    /// `income × emergencyMultiplier` before the hard cap, for the struck-through target
    /// (`EmergencyMultiplierPicker.swift:91-100`). Equal to `emergencyTarget` when uncapped,
    /// `null` for non-emergency accounts.
    public let emergencyTargetUncapped: Money?
    /// Whether the hard cap is actually limiting the target.
    public let isCapActive: Bool
    /// The four multiplier options resolved against this account's income and cap. Empty for
    /// non-emergency accounts.
    public let multiplierOptions: [MultiplierOptionDTO]
    /// Whether New Month step 2 lets the user edit this balance — `emergency|savings|personal`
    /// only (`ReconcileAccountsStep.swift:30-36`). Served so the client doesn't hardcode the rule.
    public let isReconcilable: Bool
    /// `"was 1,182 RON last month"` — the caption under each reconcile field.
    public let wasLastMonthDisplay: String
    /// ⚠️ The Settings account editor's balance field uses `TextField(format: .number)`
    /// (`SettingsSheet.swift:55`), **not** `AmountFormatter` — so it groups (`"1,182.5"`) and shows
    /// `"0"` rather than blank for zero. `Money.editing` is therefore NOT correct for that one
    /// field; use this instead.
    public let balanceEditorValue: String
}

/// One coloured run of an account subtitle.
public struct SubtitlePartDTO: Content, Sendable {
    /// Includes its own leading `"• "` where iOS has one — the bullet belongs to the part, not to
    /// a separator the client invents.
    public let text: String
    /// Semantic colour role: `secondary` | `accentPrimary` | `accentSecondary`.
    public let tone: String
}

public struct ExpenseDTO: Content, Sendable {
    public let id: UUID
    public let name: String
    public let amount: Money
    public let frequency: String
    public let frequencyDisplayName: String
    public let frequencyIcon: String
    public let monthlyAmount: Money
    public let annualAmount: Money
    public let icon: String
    public let categoryId: UUID?
    public let category: CategoryDTO?
    public let linkedAccountId: UUID?
    public let linkedAccountName: String
    public let isEnabled: Bool
    public let notes: String?
    public let sortOrder: Int
}

public struct CategoryDTO: Content, Sendable {
    public let id: UUID
    public let name: String
    public let icon: String
    public let colorHex: String
    public let isDefault: Bool
    public let sortOrder: Int
}

public struct DashboardDTO: Content, Sendable {
    public let currentMonthDisplay: String
    public let summary: MonthlySummaryDTO
    public let emergencyFund: EmergencyFundDTO?
    public let primaryAccount: AccountDTO?
    public let otherAccounts: [AccountDTO]
    public let expenseBreakdown: [ExpenseBreakdownItemDTO]
}

public struct MonthlySummaryDTO: Content, Sendable {
    public let income: Money
    public let expenses: Money
    /// The expenses row as the Dashboard renders it: `"-4,270 RON"`, but **`"0 RON"` when zero** —
    /// iOS gates the minus on `amount > 0`, so a zero total is unsigned. Served so the client
    /// never string-prefixes a `"-"` (which would produce `"-0 RON"`).
    public let expensesNegativeDisplay: String
    public let savings: Money
    public let personalSpending: Money
}

public struct EmergencyFundDTO: Content, Sendable {
    public let accountId: UUID
    public let accountName: String
    public let balance: Money
    public let target: Money
    public let progress: Double
    public let progressPercent: Int
    public let progressDisplay: String
    public let multiplier: Double?
    public let targetCaption: String
    public let isComplete: Bool
}

public struct ExpenseBreakdownItemDTO: Content, Sendable {
    public let id: UUID
    public let name: String
    public let icon: String
    public let amount: Money
    public let percent: Int
    public let percentDisplay: String
}

public struct ExpensesScreenDTO: Content, Sendable {
    public let totalMonthly: Money
    public let totalAnnual: Money
    public let categories: [ExpenseCategoryGroupDTO]
}

public struct ExpenseCategoryGroupDTO: Content, Sendable {
    /// Stable key for this group: the `categoryId` for a real or dangling category, or the
    /// sentinel `00000000-0000-0000-0000-000000000000` for the uncategorized bucket.
    ///
    /// Served because `category?.id` is not a safe key — two groups for two *different* deleted
    /// categories would both have `category == nil` and collide in a React list.
    public let id: UUID
    /// `nil` (i.e. **omitted**) for a dangling `categoryId` and for the uncategorized group.
    public let category: CategoryDTO?
    /// `category?.name`, or `"Uncategorized"`. Served so the fallback string isn't invented client-side.
    public let name: String
    public let enabledCount: Int
    public let totalCount: Int
    public let enabledCaption: String
    public let monthlyTotal: Money
    public let annualTotal: Money
    public let expenses: [ExpenseDTO]
}

public struct TransferPlanDTO: Content, Sendable {
    public let income: Money
    public let totalExpenses: Money
    public let availableIncome: Money
    public let totalSavings: Money
    public let accountAllocations: [AccountAllocationDTO]
    public let remainsInPrimary: Money
    public let accountExpenseTransfers: [AccountExpenseTransferDTO]
    public let remainingMoney: Money
    public let remainingDestination: String
    public let remainingDestinationDisplayName: String
    public let isBalanced: Bool
    public let hasAccountAllocations: Bool
    public let totalAccountAllocations: Money
    public let summary: String
}

/// Note the absence of `id`: `TransferPlan.AccountAllocation` mints a fresh `UUID()` on every
/// recomputation, so exposing it would hand the client an unstable React key. `accountId` is
/// stable and is what the client should key on.
public struct AccountAllocationDTO: Content, Sendable {
    public let accountId: UUID
    public let accountName: String
    public let accountType: String
    public let icon: String
    public let amount: Money
    public let progressBefore: Double?
    public let progressAfter: Double?
    public let progressBeforePercent: Int?
    public let progressAfterPercent: Int?
    public let progressChangeDisplay: String?
    /// **New Month row note** (`TransferPlanStep.swift:188-193`). When the account is an emergency
    /// account **and** `isComplete`, iOS renders `"Completes fund to 100%!"` **instead of**
    /// `progressChangeDisplay`; otherwise it renders `progressChangeDisplay`. That replacement is
    /// already applied here, so the New Month row renders this field and nothing else.
    ///
    /// Deliberately **not** unified with `onboardingCompletionNote`: the two screens use different
    /// wording, different structure (replace vs append) and different conditions (New Month also
    /// requires `accountType == .emergency`). One field would be wrong on one screen (R30).
    public let newMonthNote: String?
    /// **Onboarding appended label** (`TransferPlanScreen.swift:375-386`). `"Target reached!"` when
    /// `isComplete`, rendered as an extra ✓ row *beside* `progressChangeDisplay` rather than
    /// replacing it. `nil` when not complete — and also `nil` when `progressChangeDisplay` is
    /// `nil`, because iOS gates the whole block on the progress string existing.
    ///
    /// Note this is **not** gated on `accountType`, unlike the New Month note.
    public let onboardingCompletionNote: String?
    /// Semantic colour for `progressChangeDisplay` on the onboarding summary: `positive` when
    /// `isComplete`, else `warning` (iOS: `.green` / `.orange`). `nil` with no progress string.
    public let progressChangeTone: String?
    public let targetAmount: Money?
    public let currentBalance: Money
    public let isComplete: Bool
}

public struct AccountExpenseTransferDTO: Content, Sendable {
    public let accountId: UUID
    public let accountName: String
    public let amount: Money
    public let expenseNames: [String]
}

// MARK: - Reference tables

public struct ReferenceDTO: Content, Sendable {
    public let accountTypes: [AccountTypeRefDTO]
    public let frequencies: [FrequencyRefDTO]
    public let allocationModes: [DescribedRefDTO]
    public let savingsInputModes: [SimpleRefDTO]
    public let remainingMoneyDestinations: [DestinationRefDTO]
    public let currencies: [CurrencyRefDTO]
    public let savingsConstants: SavingsConstantsDTO
    /// 37 icons, `AddExpenseSheet.swift:193-231`. NOT the same set as `categoryIcons`.
    public let expenseIcons: [String]
    /// 12 icons, `CategoryManagementView.swift:133-137`. Overlaps `expenseIcons` on only 5
    /// symbols, and `calendar` appears here but not there — sharing one array breaks a screen.
    public let categoryIcons: [String]
    /// 10 colours, `CategoryManagementView.swift:120-131`.
    public let categoryColors: [String]
    public let defaultNewCategory: DefaultCategoryDTO
    public let defaultExpenseIcon: String
    /// The four emergency-multiplier options with their captions, without income resolution.
    /// For resolved targets use `account.multiplierOptions`.
    public let emergencyMultiplierOptions: [MultiplierOptionDTO]
    /// The three "Quick suggestions" chips on Add Account. ⚠️ The chip labelled "Emergency"
    /// creates a `.savings` account — a real iOS bug, reproduced faithfully. Labels are raw
    /// English with no `.localized`, so they render English in Romanian too.
    public let accountSuggestions: [AccountSuggestionDTO]
}

public struct AccountTypeRefDTO: Content, Sendable {
    public let value: String
    public let displayName: String
    public let description: String
    public let icon: String
    public let hasBehavior: Bool
    public let isUnique: Bool
}

public struct FrequencyRefDTO: Content, Sendable {
    public let value: String
    public let displayName: String
    public let icon: String
}

public struct DescribedRefDTO: Content, Sendable {
    public let value: String
    public let displayName: String
    public let description: String
}

public struct SimpleRefDTO: Content, Sendable {
    public let value: String
    public let displayName: String
}

public struct DestinationRefDTO: Content, Sendable {
    public let value: String
    public let displayName: String
    public let description: String
    public let icon: String
}

public struct CurrencyRefDTO: Content, Sendable {
    public let value: String
    public let symbol: String
    public let displayName: String
}

public struct SavingsConstantsDTO: Content, Sendable {
    public let minimumPercentage: Double
    public let maximumPercentage: Double
    public let recommendedPercentage: Double
    public let presets: [Double]
    public let defaultBoostMultiplier: Double
    public let defaultEmergencyMultiplier: Double
    /// Granularity of `savingsSliderPositions`. The split sliders genuinely use `step: 0.01`
    /// (`SavingsScreen.swift:178`); see the ⚠️ in API-CONTRACT §2.7 about the main slider.
    public let step: Double
    /// `SavingsSlider.swift:18` — a drag within this distance of a `snapValues` entry locks on.
    public let snapThreshold: Double
    /// `SavingsSlider.swift:181` — the increment for keyboard/accessibility adjustment.
    public let accessibilityStep: Double
    /// `SavingsSlider.swift:119` — where a drag locks on and fires a haptic.
    public let snapValues: [Double]
    /// `SavingsSlider.swift:160` — inclusive range that shows "Great savings rate!".
    public let greatRateRange: [Double]
}

public struct DefaultCategoryDTO: Content, Sendable {
    public let icon: String
    public let colorHex: String
    public let sortOrder: Int
}

// MARK: - Preview responses

public struct OnboardingPreviewResponse: Content, Sendable {
    public let availableIncome: Money
    /// The prioritized-mode figure behind step 6's "That's 1,182 RON/month".
    public let savingsAmount: Money
    public let totalExpenses: Money
    public let accounts: [AccountDTO]
    public let transferPlan: TransferPlanDTO
    public let savingsSliderPositions: [SliderPositionDTO]
    public let splitSliderPositions: [SliderPositionDTO]
    public let split: SplitAllocationDTO
    public let boostedPercentDisplay: String
}

public struct NewMonthPreviewResponse: Content, Sendable {
    public let transferPlan: TransferPlanDTO
    /// Remaining money that had nowhere to go, because `remainingDestination` names a role no
    /// account fills. `null` in the normal case.
    public let unallocatedRemainingMoney: Money?
    public let projectedBalances: [ProjectedBalanceDTO]
}

public struct ProjectedBalanceDTO: Content, Sendable {
    public let accountId: UUID
    public let accountName: String
    public let before: Money
    public let after: Money
}

/// Live values for the Add/Edit Expense sheet's unsaved draft.
///
/// Exists so the "Monthly Equivalent" row needs no client arithmetic. The operation is
/// `amount × Frequency.annual.monthlyMultiplier` where the multiplier is `Decimal(1)/12` — a
/// 28-significant-digit constant. **Multiplying by it is not the same as dividing by 12**, and the
/// result then needs the same half-even rounding as every other amount, which is exactly what a
/// JS `/ 12` would get wrong (`1250 / 12 = 104.1666…`).
public struct ExpensePreviewResponse: Content, Sendable {
    /// The amount as entered.
    public let amount: Money
    /// `ExpenseEntry.monthlyAmount` — `amount` when monthly, `amount × (1/12)` when annual.
    public let monthlyAmount: Money
    /// `ExpenseEntry.annualAmount` — `amount × 12` when monthly, `amount` when annual.
    public let annualAmount: Money
    /// The value the **"Monthly Equivalent"** row renders (`AddExpenseSheet.swift:32-35`).
    /// Identical to `monthlyAmount`; named separately because that is the row's own semantics.
    public let monthlyEquivalent: Money
    /// Whether iOS renders that row at all: **annual frequency and a positive amount**
    /// (`PARITY-SPEC.md §5.3` item 2). Served so the client doesn't reinvent the condition.
    public let showsMonthlyEquivalent: Bool
}

public struct CategoriesResponse: Content, Sendable {
    public let categories: [CategoryDTO]
}

public struct TransferPlanResponse: Content, Sendable {
    public let transferPlan: TransferPlanDTO
}
