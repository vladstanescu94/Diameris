import SwiftUI
import DesignSystem
import Domain
import Utilities

/// Every total shown here is computed by Domain's `SavingsAllocationEntry`.
struct SettingsSavingsSection: View {
    @Binding var allocation: SavingsAllocationEntry
    let availableIncome: Decimal
    let currencyCode: String
    let hasEmergencyAccount: Bool
    let hasSavingsAccount: Bool

    private static let boostMultipliers: [Double] = [2, 3]

    private var splitTotal: Decimal {
        allocation.splitTotal(availableIncome: availableIncome)
    }

    private var splitExceedsIncome: Bool {
        splitTotal > availableIncome && availableIncome > 0
    }

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Picker("Allocation Mode".localized, selection: $allocation.allocationMode) {
                    ForEach(AllocationMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Text(allocation.allocationMode.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            switch allocation.allocationMode {
            case .prioritized:
                prioritizedContent
            case .split:
                splitContent
            }
        } header: {
            Text("Savings".localized)
        } footer: {
            Text(splitExceedsIncome && allocation.allocationMode == .split
                 ? "Total exceeds available income. Amounts will be reduced proportionally.".localized
                 : "Savings are calculated from income after expenses.".localized)
        }
    }

    @ViewBuilder
    private var prioritizedContent: some View {
        Picker("Savings Type".localized, selection: $allocation.savingsInputMode) {
            ForEach(SavingsInputMode.allCases) { mode in
                Text(mode.displayName).tag(mode)
            }
        }
        .pickerStyle(.segmented)

        switch allocation.savingsInputMode {
        case .percentage:
            PercentageSliderRow(
                title: "Savings Rate".localized,
                value: $allocation.percentage,
                tint: DiamerisColors.accentPrimary
            )

            Toggle("Savings Boost".localized, isOn: $allocation.boostEnabled)
                .tint(DiamerisColors.accentPrimary)
                .disabled(!allocation.boostEnabled && !allocation.canEnableBoost)
                .onChange(of: allocation.percentage) { allocation = allocation.withSafeBoost }
                .onChange(of: allocation.boostMultiplier) { allocation = allocation.withSafeBoost }

            if allocation.boostEnabled {
                Picker("Boost Multiplier".localized, selection: $allocation.boostMultiplier) {
                    ForEach(Self.boostMultipliers, id: \.self) { multiplier in
                        Text(verbatim: multiplier.formatted(.number.precision(.fractionLength(0))) + "×")
                            .tag(multiplier)
                    }
                }

                LabeledContent("Effective Rate".localized) {
                    Text(allocation.effectivePercentage, format: .percent.precision(.fractionLength(0)))
                        .foregroundStyle(DiamerisColors.accentPrimary)
                        .fontWeight(.medium)
                        .monospacedDigit()
                }
            }
        case .fixedAmount:
            AmountField("Monthly Savings".localized, amount: $allocation.fixedAmount, currencyCode: currencyCode)
        }
    }

    @ViewBuilder
    private var splitContent: some View {
        if hasEmergencyAccount {
            SplitContributionRows(
                title: "Emergency".localized,
                icon: AccountType.emergency.icon,
                inputMode: $allocation.splitEmergencyInputMode,
                percentage: $allocation.splitEmergencyPercentage,
                amount: $allocation.splitEmergencyAmount,
                currencyCode: currencyCode
            )
        }

        if hasSavingsAccount {
            SplitContributionRows(
                title: "Savings".localized,
                icon: AccountType.savings.icon,
                inputMode: $allocation.splitSavingsInputMode,
                percentage: $allocation.splitSavingsPercentage,
                amount: $allocation.splitSavingsAmount,
                currencyCode: currencyCode
            )
        }

        if hasEmergencyAccount || hasSavingsAccount {
            LabeledContent {
                Text(AmountFormatter.formatForDisplay(splitTotal, currency: currencyCode))
                    .bold()
                    .foregroundStyle(splitExceedsIncome ? DiamerisColors.negative : DiamerisColors.accentPrimary)
                    .monospacedDigit()
            } label: {
                Text("Total Monthly".localized)
                    .bold()
            }
        }
    }
}

private struct SplitContributionRows: View {
    let title: String
    let icon: String
    @Binding var inputMode: SavingsInputMode
    @Binding var percentage: Double
    @Binding var amount: Decimal
    let currencyCode: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.subheadline)
            .accessibilityAddTraits(.isHeader)

        Picker(title, selection: $inputMode) {
            ForEach(SavingsInputMode.allCases) { mode in
                Text(mode.displayName).tag(mode)
            }
        }
        .pickerStyle(.segmented)

        switch inputMode {
        case .percentage:
            PercentageSliderRow(title: String(localized: "Rate", comment: "Label for a savings contribution percentage slider"), value: $percentage, tint: DiamerisColors.accentSecondary)
        case .fixedAmount:
            AmountField(String(localized: "Monthly Amount", comment: "Label for a fixed monthly contribution amount in split savings mode"), amount: $amount, currencyCode: currencyCode)
        }
    }
}
