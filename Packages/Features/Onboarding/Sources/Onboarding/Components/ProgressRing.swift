import SwiftUI
import DesignSystem

/// A circular progress ring with animated fill and optional percentage label.
public struct ProgressRing: View {
    let progress: Double  // 0.0 - 1.0
    let size: CGFloat
    let lineWidth: CGFloat
    let showLabel: Bool
    let color: Color

    @State private var animatedProgress: Double = 0

    public init(
        progress: Double,
        size: CGFloat = 60,
        lineWidth: CGFloat = 6,
        showLabel: Bool = true,
        color: Color = DiamerisColors.accentSecondary
    ) {
        self.progress = progress
        self.size = size
        self.lineWidth = lineWidth
        self.showLabel = showLabel
        self.color = color
    }

    public var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    Color.secondary.opacity(0.15),
                    lineWidth: lineWidth
                )

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))

            // Percentage label
            if showLabel {
                Text("\(Int(animatedProgress * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
                    .contentTransition(.numericText())
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(SpringPreset.smooth) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(SpringPreset.smooth) {
                animatedProgress = newValue
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "\(Int(progress * 100)) percent complete"))
    }
}

// MARK: - Variants

extension ProgressRing {
    /// Small progress ring (40pt)
    public static func small(
        progress: Double,
        color: Color = DiamerisColors.accentSecondary
    ) -> ProgressRing {
        ProgressRing(
            progress: progress,
            size: 40,
            lineWidth: 4,
            showLabel: false,
            color: color
        )
    }

    /// Medium progress ring (60pt) - default
    public static func medium(
        progress: Double,
        showLabel: Bool = true,
        color: Color = DiamerisColors.accentSecondary
    ) -> ProgressRing {
        ProgressRing(
            progress: progress,
            size: 60,
            lineWidth: 6,
            showLabel: showLabel,
            color: color
        )
    }

    /// Large progress ring (80pt)
    public static func large(
        progress: Double,
        showLabel: Bool = true,
        color: Color = DiamerisColors.accentSecondary
    ) -> ProgressRing {
        ProgressRing(
            progress: progress,
            size: 80,
            lineWidth: 8,
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
