import Domain
import Foundation
import Utilities

/// Builds the pre-resolved picker/slider tables (R13, R18.1–R18.3).
///
/// Every money figure here comes from a `Domain` method — `calculateSavings`,
/// `resolvedSplitEmergencyAmount`, `splitTotal`, `emergencyTarget`. This file chooses *which*
/// positions to enumerate and calls Domain for each one; it does not compute any of them.
public struct PickerAssembler: Sendable {

    public init() {}

    // MARK: - Constants transcribed from iOS components

    /// `SavingsSlider.swift:15-17`
    public static let minimumPercentage = 0.05
    public static let maximumPercentage = 0.50
    public static let recommendedPercentage = 0.25
    /// `SavingsSlider.swift:119` — drag snap targets.
    public static let snapValues: [Double] = [0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40]
    /// `SavingsSlider.swift:18` — a drag within this distance of a snap value locks onto it.
    public static let snapThreshold = 0.02
    /// `SavingsSlider.swift:160` — "Great savings rate!" badge, inclusive.
    public static let greatRateRange = (low: 0.20, high: 0.30)
    /// `SavingsSlider.swift:181` — keyboard/accessibility increment.
    public static let accessibilityStep = 0.05
    /// The granularity we enumerate at, matching the split sliders' explicit `step: 0.01`
    /// (`SavingsScreen.swift:178, 224`). See the ⚠️ note in `API-CONTRACT.md` about the main
    /// slider being continuous on iOS.
    public static let sliderStep = 0.01

    /// `EmergencyMultiplierPicker.swift:15`
    public static let multiplierOptions: [Double] = [3.0, 4.0, 5.0, 6.0]

    /// `EmergencyMultiplierPicker.swift:188-198`
    public static func multiplierCaption(_ multiplier: Double) -> String {
        switch multiplier {
        case 3.0: "Minimum recommended"
        case 4.0: "Standard protection"
        case 5.0: "Enhanced protection"
        case 6.0: "Maximum security"
        default: ""
        }
    }

    /// `"3×"` — U+00D7 MULTIPLICATION SIGN, as the picker renders it.
    public static func multiplierDisplay(_ multiplier: Double) -> String {
        let whole = multiplier == multiplier.rounded() ? String(Int(multiplier)) : String(multiplier)
        return "\(whole)×"
    }

    /// The percentages we enumerate: 0.05 … 0.50 at `sliderStep`, inclusive of both ends.
    static func percentages() -> [Double] {
        let steps = Int(((maximumPercentage - minimumPercentage) / sliderStep).rounded())
        return (0...steps).map { index in
            // Rebuilt from the integer index each time so accumulated FP error can't drift.
            (minimumPercentage * 100 + Double(index) * sliderStep * 100).rounded() / 100
        }
    }

    // MARK: - Savings slider

    /// The main savings slider, boost-aware: each position's money is
    /// `SavingsAllocationEntry.calculateSavings(availableIncome:)` with that percentage.
    public func savingsSliderPositions(
        allocation: SavingsAllocationEntry,
        availableIncome: Decimal,
        money: MoneyFormatter
    ) -> [SliderPositionDTO] {
        Self.percentages().map { percentage in
            var candidate = allocation
            candidate.percentage = percentage
            candidate.savingsInputMode = .percentage
            candidate.allocationMode = .prioritized
            return position(
                percentage: percentage,
                savings: money(candidate.calculateSavings(availableIncome: availableIncome))
            )
        }
    }

    /// The split-side sliders: each position's money is `availableIncome × percentage`, via
    /// Domain's `resolvedSplitEmergencyAmount`. Both sides use the same formula, so one table
    /// serves both.
    public func splitSliderPositions(
        availableIncome: Decimal,
        money: MoneyFormatter
    ) -> [SliderPositionDTO] {
        Self.percentages().map { percentage in
            var candidate = SavingsAllocationEntry()
            candidate.splitEmergencyInputMode = .percentage
            candidate.splitEmergencyPercentage = percentage
            return position(
                percentage: percentage,
                savings: money(candidate.resolvedSplitEmergencyAmount(availableIncome: availableIncome))
            )
        }
    }

    private func position(percentage: Double, savings: Money) -> SliderPositionDTO {
        SliderPositionDTO(
            percentage: percentage,
            percent: truncatedPercent(percentage),
            percentDisplay: percentDisplay(percentage),
            savings: savings,
            isRecommended: percentage == Self.recommendedPercentage,
            showsGreatRateBadge: percentage >= Self.greatRateRange.low
                && percentage <= Self.greatRateRange.high,
            isSnapValue: Self.snapValues.contains(percentage)
        )
    }

    // MARK: - Emergency multiplier

    /// The four options resolved against a specific income and hard cap.
    public func multiplierOptions(
        selected: Double?,
        hardCap: Decimal?,
        monthlyIncome: Decimal,
        money: MoneyFormatter
    ) -> [MultiplierOptionDTO] {
        Self.multiplierOptions.map { multiplier in
            // Both targets come from Domain: the capped one via `emergencyTarget`, the uncapped
            // one via the same call with the cap removed. No `income × multiplier` here.
            let capped = AccountEntry(
                name: "", accountType: .emergency,
                emergencyMultiplier: multiplier, emergencyHardCap: hardCap
            ).emergencyTarget(monthlyIncome: monthlyIncome) ?? 0
            let uncapped = AccountEntry(
                name: "", accountType: .emergency,
                emergencyMultiplier: multiplier, emergencyHardCap: nil
            ).emergencyTarget(monthlyIncome: monthlyIncome) ?? 0

            return MultiplierOptionDTO(
                multiplier: multiplier,
                display: Self.multiplierDisplay(multiplier),
                caption: Self.multiplierCaption(multiplier),
                target: money(capped),
                targetUncapped: money(uncapped),
                isCapActive: capped < uncapped,
                isSelected: selected == multiplier
            )
        }
    }

    // MARK: - Split mode

    public func split(
        allocation: SavingsAllocationEntry,
        availableIncome: Decimal,
        plan: TransferPlan,
        money: MoneyFormatter
    ) -> SplitAllocationDTO {
        let requestedTotal = allocation.splitTotal(availableIncome: availableIncome)

        func side(
            inputMode: SavingsInputMode,
            percentage: Double,
            fixedAmount: Decimal,
            resolved: Decimal
        ) -> SplitAllocationDTO.SplitSideDTO {
            SplitAllocationDTO.SplitSideDTO(
                inputMode: inputMode.rawValue,
                percentage: percentage,
                percent: truncatedPercent(percentage),
                percentDisplay: percentDisplay(percentage),
                fixedAmount: money(fixedAmount),
                resolvedAmount: money(resolved)
            )
        }

        return SplitAllocationDTO(
            emergency: side(
                inputMode: allocation.splitEmergencyInputMode,
                percentage: allocation.splitEmergencyPercentage,
                fixedAmount: allocation.splitEmergencyAmount,
                resolved: allocation.resolvedSplitEmergencyAmount(availableIncome: availableIncome)
            ),
            savings: side(
                inputMode: allocation.splitSavingsInputMode,
                percentage: allocation.splitSavingsPercentage,
                fixedAmount: allocation.splitSavingsAmount,
                resolved: allocation.resolvedSplitSavingsAmount(availableIncome: availableIncome)
            ),
            requestedTotal: money(requestedTotal),
            // ⚠️ This one division mirrors `TransferCalculator.swift:161-163`, which is `private`,
            // so it cannot be called from here. It is the only arithmetic in the assembly layer
            // and it is pinned by the split golden vectors. The clean fix is a public
            // `splitScaleRatio(availableIncome:)` on `SavingsAllocationEntry` — an additive Domain
            // change I have flagged for approval rather than made unilaterally.
            scaleRatio: requestedTotal > availableIncome && requestedTotal > 0
                ? DecimalString(availableIncome / requestedTotal)
                : DecimalString(1),
            wasScaledDown: requestedTotal > availableIncome,
            // Taken from the plan, so Domain's proportional reduction is already applied and no
            // ratio arithmetic happens on this side of the wire.
            // ⚠️ Summed, not `.first` — in Split mode with the emergency fund at target the
            // overflow redirects to savings and the SAME account appears TWICE in
            // `accountAllocations` (e.g. "+1,182" and "+3,548"). Taking the first would under-report
            // by the second row's amount (R25 row 8).
            actualEmergencyAllocation: money(
                plan.accountAllocations
                    .filter { $0.accountType == .emergency }
                    .reduce(Decimal(0)) { $0 + $1.amount }
            ),
            actualSavingsAllocation: money(
                plan.accountAllocations
                    .filter { $0.accountType == .savings }
                    .reduce(Decimal(0)) { $0 + $1.amount }
            )
        )
    }

    // MARK: - Boost

    /// `SettingsSheet.swift:218` — clamps at 100 *after* multiplying, where Domain clamps at 1.0
    /// *before*. Identical results today; served so the rule has one implementation.
    public func boostedPercentDisplay(_ allocation: SavingsAllocationEntry) -> String {
        let value = min(100, allocation.percentage * allocation.boostMultiplier * 100)
        return "\(Int(value))%"
    }

    // MARK: - Account editor balance field

    /// ⚠️ `SettingsSheet.swift:55` uses `TextField(value:format: .number)`, **not**
    /// `AmountFormatter`, so this field groups and shows `"0"` instead of blank for zero —
    /// unlike every other amount field in the app. Served separately so the client is not
    /// tempted to reuse `Money.editing` here.
    public func balanceEditorValue(_ amount: Decimal) -> String {
        amount.formatted(.number)
    }
}
