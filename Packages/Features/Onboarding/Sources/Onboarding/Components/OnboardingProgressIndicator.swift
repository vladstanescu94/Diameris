import SwiftUI
import DesignSystem

/// Animated glass progress indicator that morphs between steps
struct OnboardingProgressIndicator: View {
    let currentStep: OnboardingViewModel.OnboardingStep
    let totalSteps: Int

    @Namespace private var progressNamespace

    /// Adjusted step index (0-based for the visible progress steps)
    /// Excludes welcome (step 0) from progress visualization
    private var adjustedStepIndex: Int {
        max(0, currentStep.rawValue - 1) // Offset by 1 to skip welcome
    }

    private var progress: CGFloat {
        guard totalSteps > 1 else { return 0 }
        return CGFloat(adjustedStepIndex) / CGFloat(totalSteps - 1)
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // Background track
            Capsule()
                .fill(Color.secondary.opacity(Opacity.subtle))
                .frame(width: ComponentSize.progressBarMaxWidth, height: ComponentSize.progressTrackHeight)

            // Animated fill
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
                .frame(
                    width: ComponentSize.progressBarMaxWidth * (progress + ComponentSize.progressMinFillScale),
                    height: ComponentSize.progressTrackHeight
                )

            // Dots
            HStack(spacing: 0) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    let isCompleted = index <= adjustedStepIndex
                    let isCurrent = index == adjustedStepIndex

                    Circle()
                        .fill(isCompleted
                            ? DiamerisColors.accentPrimary
                            : Color.secondary.opacity(Opacity.subtle))
                        .frame(
                            width: isCurrent ? ComponentSize.progressDotMedium : ComponentSize.progressDot,
                            height: isCurrent ? ComponentSize.progressDotMedium : ComponentSize.progressDot
                        )
                        .overlay {
                            if isCurrent {
                                Circle()
                                    .stroke(DiamerisColors.accentPrimary.opacity(Opacity.half), lineWidth: 2)
                                    .frame(width: ComponentSize.progressRingSize, height: ComponentSize.progressRingSize)
                                    .scaleEffect(isCurrent ? 1.0 : Opacity.half)
                                    .opacity(isCurrent ? 1 : 0)
                            }
                        }
                        .scaleEffect(isCurrent ? ScaleEffect.prominent : 1.0)
                        .animation(SpringPreset.snappy, value: isCurrent)

                    if index < totalSteps - 1 {
                        Spacer()
                    }
                }
            }
            .frame(width: ComponentSize.progressBarMaxWidth)
        }
        .frame(width: ComponentSize.progressBarMaxWidth, height: ComponentSize.progressIndicatorHeight)
        .animation(SpringPreset.responsive, value: currentStep)
    }
}

#Preview {
    VStack(spacing: 40) {
        OnboardingProgressIndicator(
            currentStep: .name,
            totalSteps: 5
        )
        OnboardingProgressIndicator(
            currentStep: .income,
            totalSteps: 5
        )
        OnboardingProgressIndicator(
            currentStep: .savingsGoals,
            totalSteps: 5
        )
        OnboardingProgressIndicator(
            currentStep: .accounts,
            totalSteps: 5
        )
        OnboardingProgressIndicator(
            currentStep: .expenses,
            totalSteps: 5
        )
    }
    .padding()
}
