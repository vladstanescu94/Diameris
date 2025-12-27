import SwiftUI
import DesignSystem
import Utilities

/// Picker for selecting goal target type and value.
public struct GoalTargetPicker: View {
    @Binding var targetType: TargetType
    @Binding var targetValue: Decimal?
    let monthlyIncome: Decimal
    let currency: String

    private let multiplierOptions: [Decimal] = [3, 4, 6]

    public init(
        targetType: Binding<TargetType>,
        targetValue: Binding<Decimal?>,
        monthlyIncome: Decimal,
        currency: String
    ) {
        self._targetType = targetType
        self._targetValue = targetValue
        self.monthlyIncome = monthlyIncome
        self.currency = currency
    }

    private var calculatedTarget: Decimal? {
        switch targetType {
        case .incomeMultiplier:
            guard let multiplier = targetValue else { return nil }
            return monthlyIncome * multiplier
        case .fixedAmount:
            return targetValue
        case .unlimited:
            return nil
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Multiplier selector for income-based targets
            if targetType == .incomeMultiplier {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(String(localized: "Target multiplier"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: Spacing.sm) {
                        ForEach(multiplierOptions, id: \.self) { multiplier in
                            MultiplierButton(
                                multiplier: multiplier,
                                isSelected: targetValue == multiplier,
                                onTap: {
                                    HapticManager.lightTap()
                                    targetValue = multiplier
                                }
                            )
                        }
                    }

                    // Show calculated target
                    if let target = calculatedTarget {
                        HStack {
                            Text(String(localized: "Target:"))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(AmountFormatter.formatForDisplay(target, currency: currency))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(DiamerisColors.accentSecondary)
                        }
                        .padding(.top, Spacing.xxs)
                    }
                }
            }
        }
    }
}

/// Button for selecting a multiplier value.
private struct MultiplierButton: View {
    let multiplier: Decimal
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text("\(Int(truncating: multiplier as NSNumber))x")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(isSelected ? .white : .primary)
                .frame(width: 60, height: 44)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: CornerRadius.medium)
                            .fill(DiamerisColors.accentSecondary)
                    } else {
                        RoundedRectangle(cornerRadius: CornerRadius.medium)
                            .fill(Color.secondary.opacity(0.1))
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "\(Int(truncating: multiplier as NSNumber)) times income"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var targetType: TargetType = .incomeMultiplier
        @State private var targetValue: Decimal? = 3

        var body: some View {
            VStack(spacing: Spacing.lg) {
                GoalTargetPicker(
                    targetType: $targetType,
                    targetValue: $targetValue,
                    monthlyIncome: 14303,
                    currency: "RON"
                )
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
