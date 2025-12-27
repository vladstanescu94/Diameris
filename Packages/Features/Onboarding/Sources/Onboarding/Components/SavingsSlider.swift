import SwiftUI
import DesignSystem
import Utilities

/// Custom slider for selecting savings percentage with haptic feedback.
public struct SavingsSlider: View {
    @Binding var percentage: Double
    let availableIncome: Decimal
    let currency: String

    @State private var isDragging = false

    private let minimumPercentage: Double = 0.05
    private let maximumPercentage: Double = 0.50
    private let recommendedPercentage: Double = 0.25
    private let snapThreshold: Double = 0.02  // Snap within 2%

    public init(
        percentage: Binding<Double>,
        availableIncome: Decimal,
        currency: String
    ) {
        self._percentage = percentage
        self.availableIncome = availableIncome
        self.currency = currency
    }

    private var savingsAmount: Decimal {
        availableIncome * Decimal(percentage)
    }

    private var displayPercentage: Int {
        Int(percentage * 100)
    }

    public var body: some View {
        VStack(spacing: Spacing.md) {
            // Percentage display
            HStack(alignment: .lastTextBaseline) {
                Text("\(displayPercentage)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(DiamerisColors.accentPrimary)
                    .contentTransition(.numericText())

                Text("%")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
            .animation(SpringPreset.responsive, value: displayPercentage)

            // Savings amount
            Text(String(localized: "That's \(AmountFormatter.formatForDisplay(savingsAmount, currency: currency))/month"))
                .font(.headline)
                .foregroundStyle(.secondary)

            // Custom slider
            GeometryReader { geometry in
                let width = geometry.size.width
                let normalizedValue = (percentage - minimumPercentage) / (maximumPercentage - minimumPercentage)
                let thumbPosition = width * normalizedValue

                ZStack(alignment: .leading) {
                    // Track background
                    Capsule()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 8)

                    // Filled track
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    DiamerisColors.accentPrimary,
                                    DiamerisColors.accentSecondary
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, thumbPosition + 12), height: 8)

                    // Recommended marker
                    let recommendedPosition = width * ((recommendedPercentage - minimumPercentage) / (maximumPercentage - minimumPercentage))
                    Circle()
                        .fill(DiamerisColors.accentSecondary)
                        .frame(width: 6, height: 6)
                        .offset(x: recommendedPosition - 3)

                    // Thumb
                    Circle()
                        .fill(.white)
                        .frame(width: 24, height: 24)
                        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                        .overlay {
                            Circle()
                                .stroke(DiamerisColors.accentPrimary, lineWidth: 2)
                        }
                        .scaleEffect(isDragging ? 1.1 : 1.0)
                        .offset(x: thumbPosition - 12)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    isDragging = true
                                    let newValue = value.location.x / width
                                    let clampedValue = max(0, min(1, newValue))
                                    var newPercentage = minimumPercentage + clampedValue * (maximumPercentage - minimumPercentage)

                                    // Snap to common values
                                    let snapValues: [Double] = [0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40]
                                    for snapValue in snapValues {
                                        if abs(newPercentage - snapValue) < snapThreshold {
                                            newPercentage = snapValue
                                            HapticManager.lightTap()
                                            break
                                        }
                                    }

                                    percentage = newPercentage
                                }
                                .onEnded { _ in
                                    isDragging = false
                                    HapticManager.mediumTap()
                                }
                        )
                }
            }
            .frame(height: 24)

            // Min/max labels
            HStack {
                Text("5%")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Spacer()

                Text(String(localized: "25% recommended"))
                    .font(.caption)
                    .foregroundStyle(DiamerisColors.accentSecondary)

                Spacer()

                Text("50%")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            // Recommendation badge
            if percentage >= 0.20 && percentage <= 0.30 {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(DiamerisColors.accentSecondary)
                    Text(String(localized: "Great savings rate!"))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(DiamerisColors.accentSecondary)
                }
                .padding(.vertical, Spacing.xs)
                .padding(.horizontal, Spacing.sm)
                .background(DiamerisColors.accentSecondary.opacity(0.1))
                .clipShape(Capsule())
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Savings percentage"))
        .accessibilityValue(String(localized: "\(displayPercentage) percent, \(AmountFormatter.formatForDisplay(savingsAmount, currency: currency)) per month"))
        .accessibilityAdjustableAction { direction in
            let step: Double = 0.05
            switch direction {
            case .increment:
                percentage = min(maximumPercentage, percentage + step)
            case .decrement:
                percentage = max(minimumPercentage, percentage - step)
            @unknown default:
                break
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var percentage: Double = 0.25

        var body: some View {
            VStack(spacing: Spacing.xl) {
                SavingsSlider(
                    percentage: $percentage,
                    availableIncome: 10000,
                    currency: "RON"
                )
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
