import Domain
import Foundation
import Vapor

// Pre-resolved picker/slider tables.
//
// These all exist for one reason (R2/R18): iOS computes a display value inline from two stored
// values, and if we shipped only the stored values the client would have to do the arithmetic.
// The fix is always the same shape — **enumerate the resolved outcomes server-side** — so a drag
// or a tap becomes an index lookup rather than a calculation.

/// One reachable position on the savings-percentage slider, fully resolved.
public struct SliderPositionDTO: Content, Sendable {
    /// The raw fraction, e.g. `0.25`.
    public let percentage: Double
    /// `Int(percentage * 100)` — truncated, as every iOS percent label is.
    public let percent: Int
    /// `"25%"`.
    public let percentDisplay: String
    /// The money this position yields. For the main slider this is boost-aware
    /// (`SavingsAllocationEntry.calculateSavings`); for the split sliders it is
    /// `availableIncome × percentage` (`resolvedSplit*Amount`).
    public let savings: Money
    /// `percentage == recommendedPercentage` (0.25) — drives the "25% recommended" tick.
    public let isRecommended: Bool
    /// `0.20...0.30` — drives the "Great savings rate!" badge (`SavingsSlider.swift:160`).
    public let showsGreatRateBadge: Bool
    /// One of `SavingsSlider`'s snap targets (`:119`), where iOS fires a haptic and locks on.
    public let isSnapValue: Bool
}

/// One option in the emergency-multiplier segmented picker, resolved against the current income
/// and hard cap so tapping 3×→6× updates live, before anything is saved.
public struct MultiplierOptionDTO: Content, Sendable {
    public let multiplier: Double
    /// `"3×"` — note U+00D7, not the letter x.
    public let display: String
    /// `EmergencyMultiplierPicker.multiplierDescription` — "Minimum recommended",
    /// "Standard protection", "Enhanced protection", "Maximum security".
    public let caption: String
    /// The effective target: `min(income × multiplier, hardCap)`.
    public let target: Money
    /// `income × multiplier`, *before* the cap. Rendered struck through when the cap bites
    /// (`EmergencyMultiplierPicker.swift:91-100`); equal to `target` otherwise.
    public let targetUncapped: Money
    /// Whether the hard cap is actually limiting this option.
    public let isCapActive: Bool
    public let isSelected: Bool
}

/// Split mode, fully resolved. Without this the client would have to compute
/// `availableIncome × percentage` per side, which is exactly what `SavingsScreen.swift:164-217`
/// does inline and what R2 forbids.
public struct SplitAllocationDTO: Content, Sendable {
    public let emergency: SplitSideDTO
    public let savings: SplitSideDTO
    /// `SavingsAllocationEntry.splitTotal(availableIncome:)` — the sum the user asked for,
    /// **before** any proportional reduction.
    public let requestedTotal: Money
    /// `availableIncome / requestedTotal` when the request overshoots, else `1`. This is the
    /// factor `TransferCalculator` applies to **both** sides (`TransferCalculator.swift:161-163`).
    public let scaleRatio: DecimalString
    /// True when `requestedTotal > availableIncome`, i.e. both sides get scaled down.
    public let wasScaledDown: Bool
    /// What actually lands, taken from the plan's allocations — already scaled by Domain, so no
    /// ratio arithmetic happens here.
    public let actualEmergencyAllocation: Money
    public let actualSavingsAllocation: Money

    public struct SplitSideDTO: Content, Sendable {
        public let inputMode: String
        public let percentage: Double
        public let percent: Int
        public let percentDisplay: String
        public let fixedAmount: Money
        /// `resolvedSplit*Amount(availableIncome:)` — what the slider caption shows. **Unscaled**,
        /// matching the screen, which renders `availableIncome × percentage` directly.
        public let resolvedAmount: Money
    }
}

/// A "Quick suggestions" chip on the Add Account sheet (`AddAccountSheet.swift:61-73`).
public struct AccountSuggestionDTO: Content, Sendable {
    public let title: String
    public let accountType: String
    public let icon: String
}
