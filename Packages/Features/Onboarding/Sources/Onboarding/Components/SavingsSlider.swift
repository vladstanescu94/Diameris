import SwiftUI
import DesignSystem
import Utilities
import Domain

public struct SavingsSlider: View {
    @Binding var percentage: Double
    /// Monthly amount the current (possibly boosted) rate saves — computed by Domain.
    let savingsAmount: Decimal
    let currency: String

    @State private var isDragging = false
    /// Decided on the first drag event; vertical drags are left to the enclosing scroll view.
    @State private var isHorizontalDrag: Bool?
    @ScaledMetric(relativeTo: .body) private var thumbSize: CGFloat = IconSize.md
    @ScaledMetric(relativeTo: .body) private var trackHeight: CGFloat = ComponentSize.progressDot

    private let minimumPercentage = SavingsAllocationEntry.minimumPercentage
    private let maximumPercentage = SavingsAllocationEntry.maximumPercentage
    private let recommendedPercentage = SavingsAllocationEntry.recommendedPercentage
    /// Whole percents the thumb snaps to from one point away while dragging.
    private static let snapPercents = [10, 15, 20, 25, 30, 35, 40]
    private static let snapValues = snapPercents.map { Double($0) / 100 }
    private static let snapDistance = 2
    private static let accessibilityStep: Double = 0.05
    /// Rates labelled "Great savings rate!" (the 20–30% financial-advice band).
    private static let recommendedRange: ClosedRange<Double> = 0.20...0.30
    private static let thumbStrokeWidth: CGFloat = 2
    private static let thumbShadowRadius: CGFloat = 4
    private static let thumbShadowOffset: CGFloat = 2

    public init(
        percentage: Binding<Double>,
        savingsAmount: Decimal,
        currency: String
    ) {
        self._percentage = percentage
        self.savingsAmount = savingsAmount
        self.currency = currency
    }

    private var displayPercentage: Int {
        Int((percentage * 100).rounded())
    }

    private var isInRecommendedRange: Bool {
        Self.recommendedRange.contains(percentage)
    }

    public var body: some View {
        VStack(spacing: Spacing.md) {
            HStack(alignment: .lastTextBaseline) {
                Text(displayPercentage, format: .number)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(DiamerisColors.accentPrimary)
                    .contentTransition(.numericText())

                Text(verbatim: "%")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
            .animation(SpringPreset.responsive, value: displayPercentage)

            Text(String(localized: "That's \(AmountFormatter.formatForDisplay(savingsAmount, currency: currency))/month", bundle: .module))
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            track
                .frame(height: thumbSize)

            HStack {
                Text(minimumPercentage, format: .percent)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("25% recommended".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(maximumPercentage, format: .percent)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if isInRecommendedRange {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(DiamerisColors.accentSecondary)
                    Text("Great savings rate!".localized)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.vertical, Spacing.xs)
                .padding(.horizontal, Spacing.sm)
                .background(DiamerisColors.accentSecondary.opacity(Opacity.faint))
                .clipShape(Capsule())
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: AnimationDuration.appear), value: isInRecommendedRange)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Savings percentage".localized)
        .accessibilityValue(String(localized: "\(displayPercentage) percent, \(AmountFormatter.formatForDisplay(savingsAmount, currency: currency)) per month", bundle: .module))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                percentage = min(maximumPercentage, percentage + Self.accessibilityStep)
            case .decrement:
                percentage = max(minimumPercentage, percentage - Self.accessibilityStep)
            @unknown default:
                break
            }
        }
    }
}

// MARK: - Drag Value

extension SavingsSlider {
    /// Rate for a drag position along the track (0 = start, 1 = end). Stored as whole
    /// percents so the saved rate matches the displayed one, and pulled onto nearby snap values.
    static func percentage(atFraction fraction: Double) -> Double {
        let minimum = SavingsAllocationEntry.minimumPercentage
        let maximum = SavingsAllocationEntry.maximumPercentage
        let rawPercentage = minimum + max(0, min(1, fraction)) * (maximum - minimum)
        // Compared as integers: in Double, 0.12 - 0.10 < 0.02, so rates two points away snapped too.
        let percent = Int((rawPercentage * 100).rounded())
        let snapped = snapPercents.first { abs(percent - $0) < snapDistance } ?? percent
        return Double(snapped) / 100
    }
}

// MARK: - Track

private extension SavingsSlider {
    var track: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let range = maximumPercentage - minimumPercentage
            let thumbPosition = width * (percentage - minimumPercentage) / range
            let recommendedPosition = width * (recommendedPercentage - minimumPercentage) / range

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(Opacity.light))
                    .frame(height: trackHeight)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [DiamerisColors.accentPrimary, DiamerisColors.accentSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, thumbPosition + thumbSize / 2), height: trackHeight)

                Circle()
                    .fill(DiamerisColors.accentSecondary)
                    .frame(width: trackHeight, height: trackHeight)
                    .offset(x: recommendedPosition - trackHeight / 2)

                thumb
                    .offset(x: thumbPosition - thumbSize / 2)
                    .gesture(dragGesture(trackWidth: width))
            }
        }
    }

    var thumb: some View {
        Circle()
            .fill(.white)
            .stroke(DiamerisColors.accentPrimary, lineWidth: Self.thumbStrokeWidth)
            .frame(width: thumbSize, height: thumbSize)
            .shadow(color: .black.opacity(Opacity.light), radius: Self.thumbShadowRadius, y: Self.thumbShadowOffset)
            .scaleEffect(isDragging ? ScaleEffect.prominent : 1.0)
            // Enlarge the hit area to the minimum touch target without changing the visuals.
            .contentShape(.rect.inset(by: -(ComponentSize.minTouchTarget - thumbSize) / 2))
    }

    func dragGesture(trackWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: Spacing.xs)
            .onChanged { value in
                if isHorizontalDrag == nil {
                    isHorizontalDrag = abs(value.translation.width) > abs(value.translation.height)
                }
                guard isHorizontalDrag == true else { return }

                if !isDragging { isDragging = true }
                let newPercentage = Self.percentage(atFraction: value.location.x / trackWidth)
                // Most drag events land on the percent already shown. Writing it anyway would
                // re-render the whole screen: the binding writes into a struct, which notifies
                // observers even when the value is unchanged.
                guard newPercentage != percentage else { return }
                // Only tick when the value lands on a new snap point.
                if Self.snapValues.contains(newPercentage) {
                    HapticManager.lightTap()
                }
                percentage = newPercentage
            }
            .onEnded { _ in
                if isHorizontalDrag == true {
                    HapticManager.mediumTap()
                }
                isDragging = false
                isHorizontalDrag = nil
            }
    }
}

#Preview {
    @Previewable @State var percentage = 0.25

    SavingsSlider(
        percentage: $percentage,
        savingsAmount: 2500,
        currency: "RON"
    )
    .padding()
}
