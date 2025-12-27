import SwiftUI
import DesignSystem
import SharedUI
import Utilities

/// A card displaying a savings goal with progress and optional balance input.
public struct GoalCard: View {
    let goal: SavingsGoalEntry
    let monthlyIncome: Decimal
    let currency: String
    let onBalanceChange: ((Decimal) -> Void)?
    let isEditable: Bool

    @State private var balanceText: String = ""
    @FocusState private var isBalanceFocused: Bool

    public init(
        goal: SavingsGoalEntry,
        monthlyIncome: Decimal,
        currency: String,
        isEditable: Bool = true,
        onBalanceChange: ((Decimal) -> Void)? = nil
    ) {
        self.goal = goal
        self.monthlyIncome = monthlyIncome
        self.currency = currency
        self.isEditable = isEditable
        self.onBalanceChange = onBalanceChange
    }

    private var targetAmount: Decimal? {
        goal.calculateTarget(monthlyIncome: monthlyIncome)
    }

    private var progress: Double {
        goal.progressPercentage(monthlyIncome: monthlyIncome) ?? 0
    }

    public var body: some View {
        HStack(spacing: Spacing.md) {
            // Progress ring
            ProgressRing.medium(
                progress: progress,
                showLabel: targetAmount != nil,
                color: goal.priority == 1 ? DiamerisColors.accentSecondary : DiamerisColors.accentPrimary
            )
            .fixedSize()

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                // Goal name and icon
                HStack(spacing: Spacing.xs) {
                    Image(systemName: goal.icon)
                        .font(.subheadline)
                        .foregroundStyle(goal.priority == 1 ? DiamerisColors.accentSecondary : DiamerisColors.accentPrimary)
                        .accessibilityHidden(true)

                    Text(goal.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }

                // Target info
                if let target = targetAmount {
                    Text(targetDescription(target: target))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("No limit - keep saving!".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                // Current balance input or display
                if isEditable {
                    HStack(spacing: Spacing.xs) {
                        Text("Current:".localized)
                            .font(.caption)
                            .foregroundStyle(.tertiary)

                        TextField(
                            "0",
                            text: $balanceText
                        )
                        .keyboardType(.decimalPad)
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                        .focused($isBalanceFocused)
                        .onChange(of: balanceText) { _, newValue in
                            if let decimal = Decimal(string: newValue.replacingOccurrences(of: ",", with: ".")) {
                                onBalanceChange?(decimal)
                            }
                        }

                        Text(currency)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                } else if goal.currentBalance > 0 {
                    Text(String(localized: "Saved: \(AmountFormatter.formatForDisplay(goal.currentBalance, currency: currency))", bundle: .module))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
        .onAppear {
            if goal.currentBalance > 0 {
                balanceText = AmountFormatter.formatForEditing(goal.currentBalance)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private func targetDescription(target: Decimal) -> String {
        let formattedTarget = AmountFormatter.formatForDisplay(target, currency: currency)
        switch goal.targetType {
        case .incomeMultiplier:
            let multiplier = Int(truncating: (goal.targetValue ?? 0) as NSNumber)
            return String(localized: "\(multiplier)x income (\(formattedTarget))", bundle: .module)
        case .fixedAmount:
            return String(localized: "Target: \(formattedTarget)", bundle: .module)
        case .unlimited:
            return "No target limit".localized
        }
    }

    private var accessibilityDescription: String {
        var description = goal.name
        if let target = targetAmount {
            let formattedTarget = AmountFormatter.formatForDisplay(target, currency: currency)
            description += ", target \(formattedTarget)"
        }
        description += ", \(Int(progress * 100)) percent complete"
        return description
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        GoalCard(
            goal: .emergencyFund(),
            monthlyIncome: 14303,
            currency: "RON",
            isEditable: true
        ) { balance in
            print("Balance changed: \(balance)")
        }

        GoalCard(
            goal: SavingsGoalEntry(
                name: "Emergency Fund",
                icon: "shield.checkered",
                targetType: .incomeMultiplier,
                targetValue: 3,
                currentBalance: 37056,
                priority: 1
            ),
            monthlyIncome: 14303,
            currency: "RON",
            isEditable: false
        )

        GoalCard(
            goal: .regularSavings(),
            monthlyIncome: 14303,
            currency: "RON",
            isEditable: false
        )
    }
    .padding()
}
