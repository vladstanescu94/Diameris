import SwiftUI
import DesignSystem

struct CompleteScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    let onComplete: () -> Void

    @State private var showCelebration = false
    @State private var contentAppeared = false
    @State private var summaryRowsAppeared: [Bool] = [false, false, false]

    var body: some View {
        ZStack {
            VStack(spacing: Spacing.xl) {
                Spacer()

                // Custom animated header for completion
                VStack(spacing: Spacing.md) {
                    AnimatedCheckmark()

                    Text(String(localized: "You're all set!"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : SlideOffset.small)

                    Text(String(localized: "Hi \(viewModel.trimmedName), your budget is ready."))
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : SlideOffset.subtle)
                }

                summaryCard

                Text("You can add more details anytime in the Budget tab.", comment: "Helper text on completion screen")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(contentAppeared ? 1 : 0)

                Spacer()

                OnboardingButton("Start Planning", isEnabled: true) {
                    HapticManager.success()
                    onComplete()
                }
                .opacity(contentAppeared ? 1 : 0)
                .offset(y: contentAppeared ? 0 : SlideOffset.standard)
                .accessibilityHint(String(localized: "Completes onboarding and opens the main app"))
            }
            .padding(Spacing.lg)

            // Celebration overlay
            if showCelebration {
                CompletionCelebration()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            triggerCelebration()
        }
    }

    private func triggerCelebration() {
        // Show celebration effects
        showCelebration = true
        HapticManager.success()

        // Stagger content appearance
        withAnimation(SpringPreset.bouncy.delay(StaggerDelay.initial)) {
            contentAppeared = true
        }

        // Stagger summary rows
        for index in 0..<summaryRowsAppeared.count {
            withAnimation(SpringPreset.responsive.delay(AnimationDuration.slow + Double(index) * StaggerDelay.standard)) {
                summaryRowsAppeared[index] = true
            }
        }
    }

    private var summaryCard: some View {
        VStack(spacing: Spacing.md) {
            SummaryRow(
                icon: "banknote.fill",
                label: String(localized: "Monthly Income"),
                value: AmountFormatter.formatForDisplay(viewModel.monthlyIncome, currency: viewModel.currency.rawValue)
            )
            .opacity(summaryRowsAppeared[0] ? 1 : 0)
            .offset(x: summaryRowsAppeared[0] ? 0 : -SlideOffset.standard)

            Divider()
                .opacity(summaryRowsAppeared[0] ? 1 : 0)

            SummaryRow(
                icon: "creditcard.fill",
                label: String(localized: "Expenses"),
                value: AmountFormatter.formatForDisplay(totalExpenses, currency: viewModel.currency.rawValue)
            )
            .opacity(summaryRowsAppeared[1] ? 1 : 0)
            .offset(x: summaryRowsAppeared[1] ? 0 : -SlideOffset.standard)

            Divider()
                .opacity(summaryRowsAppeared[1] ? 1 : 0)

            SummaryRow(
                icon: "building.columns.fill",
                label: String(localized: "Accounts"),
                value: "\(totalAccounts)"
            )
            .opacity(summaryRowsAppeared[2] ? 1 : 0)
            .offset(x: summaryRowsAppeared[2] ? 0 : -SlideOffset.standard)
        }
        .glassCard()
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "Budget summary"))
    }

    private var totalExpenses: Decimal {
        viewModel.expenses.reduce(0) { $0 + $1.amount }
    }

    private var totalAccounts: Int {
        1 + viewModel.additionalAccounts.count
    }
}

private struct SummaryRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: ComponentSize.iconContainer)
                .accessibilityHidden(true)

            Text(label)
                .font(.body)

            Spacer()

            Text(value)
                .font(.headline)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let vm = OnboardingViewModel()
    vm.name = "Vlad"
    vm.monthlyIncome = 14303
    vm.expenses[0].amount = 3000
    vm.expenses[2].amount = 300
    return CompleteScreen(viewModel: vm, onComplete: {})
}
