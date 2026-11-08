import SwiftUI
import DesignSystem

/// A circular progress ring with animated fill and optional percentage label.
public struct ProgressRing: View {
    let progress: Double  // 0.0 - 1.0, clamped
    let size: CGFloat
    let lineWidth: CGFloat
    let showLabel: Bool
    let color: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animatedProgress: Double = 0

    public init(
        progress: Double,
        size: CGFloat = ComponentSize.goalRingMedium,
        lineWidth: CGFloat = ComponentSize.goalRingLineMedium,
        showLabel: Bool = true,
        color: Color = DiamerisColors.accentSecondary
    ) {
        self.progress = min(1, max(0, progress))
        self.size = size
        self.lineWidth = lineWidth
        self.showLabel = showLabel
        self.color = color
    }

    public var body: some View {
        ZStack {
            backgroundRing
            progressRing
            percentageLabel
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(fillAnimation) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(fillAnimation) {
                animatedProgress = newValue
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Progress", bundle: .module, comment: "VoiceOver label for a circular progress ring"))
        .accessibilityValue(Text(progress, format: Self.percentFormat))
    }
}

// MARK: - Metrics

extension ProgressRing {
    enum Metrics {
        /// Start the fill at 12 o'clock rather than 3 o'clock.
        static let startAngle: Angle = .degrees(-90)
        /// Lets the percentage shrink to fit the ring at large Dynamic Type sizes.
        static let labelMinimumScale: CGFloat = 0.5
    }

    /// Locale-aware whole percent ("45%" in English, "45 %" in Romanian).
    static let percentFormat = FloatingPointFormatStyle<Double>.Percent.percent.precision(.fractionLength(0))

    private var fillAnimation: Animation? {
        reduceMotion ? nil : SpringPreset.smooth
    }
}

// MARK: - Subviews

private extension ProgressRing {
    var backgroundRing: some View {
        Circle()
            .stroke(
                Color.secondary.opacity(Opacity.light),
                lineWidth: lineWidth
            )
    }

    var progressRing: some View {
        Circle()
            .trim(from: 0, to: animatedProgress)
            .stroke(
                color,
                style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .round
                )
            )
            .rotationEffect(Metrics.startAngle)
    }

    @ViewBuilder
    var percentageLabel: some View {
        if showLabel {
            Text(animatedProgress, format: Self.percentFormat)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(Metrics.labelMinimumScale)
                .padding(.horizontal, lineWidth)
                .contentTransition(.numericText())
        }
    }
}

// MARK: - Variants

public extension ProgressRing {
    static func small(
        progress: Double,
        color: Color = DiamerisColors.accentSecondary
    ) -> ProgressRing {
        ProgressRing(
            progress: progress,
            size: ComponentSize.goalRingSmall,
            lineWidth: ComponentSize.goalRingLineSmall,
            showLabel: false,
            color: color
        )
    }

    static func medium(
        progress: Double,
        showLabel: Bool = true,
        color: Color = DiamerisColors.accentSecondary
    ) -> ProgressRing {
        ProgressRing(
            progress: progress,
            size: ComponentSize.goalRingMedium,
            lineWidth: ComponentSize.goalRingLineMedium,
            showLabel: showLabel,
            color: color
        )
    }

    static func large(
        progress: Double,
        showLabel: Bool = true,
        color: Color = DiamerisColors.accentSecondary
    ) -> ProgressRing {
        ProgressRing(
            progress: progress,
            size: ComponentSize.goalRingLarge,
            lineWidth: ComponentSize.goalRingLineLarge,
            showLabel: showLabel,
            color: color
        )
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        HStack(spacing: Spacing.lg) {
            ProgressRing.small(progress: 0.25)
            ProgressRing.small(progress: 0.50)
            ProgressRing.small(progress: 0.75)
            ProgressRing.small(progress: 1.0)
        }

        HStack(spacing: Spacing.lg) {
            ProgressRing.medium(progress: 0.33)
            ProgressRing.medium(progress: 0.66)
            ProgressRing.medium(progress: 0.92)
        }

        HStack(spacing: Spacing.lg) {
            ProgressRing.large(progress: 0.5, color: DiamerisColors.accentPrimary)
            ProgressRing.large(progress: 0.86, color: DiamerisColors.accentSecondary)
        }
    }
    .padding()
}
