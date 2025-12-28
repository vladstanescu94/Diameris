import SwiftUI
import DesignSystem
import Utilities

/// Picker for selecting emergency fund target multiplier (3x-6x monthly income).
struct EmergencyMultiplierPicker: View {
    @Binding var multiplier: Double
    let monthlyIncome: Decimal
    let currency: String

    private let multiplierOptions: [Double] = [3.0, 4.0, 5.0, 6.0]

    var body: some View {
        VStack(spacing: Spacing.sm) {
            segmentedPicker
            targetDisplay
        }
    }
}

// MARK: - Subviews

private extension EmergencyMultiplierPicker {
    var segmentedPicker: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(multiplierOptions, id: \.self) { option in
                multiplierButton(option)
            }
        }
    }

    func multiplierButton(_ option: Double) -> some View {
        Button {
            withAnimation(SpringPreset.responsive) {
                multiplier = option
            }
            HapticManager.lightTap()
        } label: {
            Text("\(Int(option))×")
                .font(.subheadline)
                .fontWeight(multiplier == option ? .semibold : .regular)
                .foregroundStyle(multiplier == option ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.small)
                        .fill(multiplier == option ? Color.orange : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }

    var targetDisplay: some View {
        let target = monthlyIncome * Decimal(multiplier)

        return HStack {
            Text("Target:".localized)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(AmountFormatter.formatForDisplay(target, currency: currency))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.orange)
                .contentTransition(.numericText())
                .animation(.easeOut(duration: AnimationDuration.appear), value: multiplier)

            Spacer()

            Text(multiplierDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .contentTransition(.interpolate)
                .animation(.easeOut(duration: AnimationDuration.appear), value: multiplier)
        }
    }

    var multiplierDescription: String {
        switch multiplier {
        case 3.0:
            return "Minimum recommended".localized
        case 4.0:
            return "Standard protection".localized
        case 5.0:
            return "Enhanced protection".localized
        case 6.0:
            return "Maximum security".localized
        default:
            return ""
        }
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        EmergencyMultiplierPicker(
            multiplier: .constant(3.0),
            monthlyIncome: 5000,
            currency: "USD"
        )

        EmergencyMultiplierPicker(
            multiplier: .constant(6.0),
            monthlyIncome: 5000,
            currency: "USD"
        )
    }
    .padding()
}
