import SwiftUI
import DesignSystem

/// Animated glass progress indicator that morphs between steps
struct OnboardingProgressIndicator: View {
    let currentStep: OnboardingViewModel.OnboardingStep
    let totalSteps: Int

    @Namespace private var progressNamespace

    private var progress: CGFloat {
        CGFloat(currentStep.rawValue) / CGFloat(totalSteps - 1)
    }

    var body: some View {
        GeometryReader { geometry in
            let totalWidth = min(geometry.size.width * Opacity.half, ComponentSize.progressBarMaxWidth)

            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color.secondary.opacity(0.15))
                    .frame(width: totalWidth, height: ComponentSize.progressTrackHeight)

                // Animated fill
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                DiamerisColors.accentPrimaryLight,
                                DiamerisColors.accentSecondaryLight
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: totalWidth * progress + ComponentSize.progressDotMedium, height: ComponentSize.progressTrackHeight)

                // Dots
                HStack(spacing: 0) {
                    ForEach(0..<totalSteps, id: \.self) { index in
                        let isCompleted = index <= currentStep.rawValue
                        let isCurrent = index == currentStep.rawValue

                        Circle()
                            .fill(isCompleted
                                ? DiamerisColors.accentPrimaryLight
                                : Color.secondary.opacity(Opacity.subtle))
                            .frame(
                                width: isCurrent ? ComponentSize.progressDotMedium : ComponentSize.progressDot,
                                height: isCurrent ? ComponentSize.progressDotMedium : ComponentSize.progressDot
                            )
                            .overlay {
                                if isCurrent {
                                    Circle()
                                        .stroke(DiamerisColors.accentPrimaryLight.opacity(Opacity.half), lineWidth: 2)
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
                .frame(width: totalWidth)
            }
            .frame(width: totalWidth)
            .frame(maxWidth: .infinity)
        }
        .frame(height: SlideOffset.standard)
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
            currentStep: .expenses,
            totalSteps: 5
        )
        OnboardingProgressIndicator(
            currentStep: .complete,
            totalSteps: 5
        )
    }
    .padding()
}
