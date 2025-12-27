import SwiftUI
import DesignSystem
import SharedUI
import Utilities

/// Screen for setting up savings goals and allocation percentage.
struct SavingsGoalsScreen: View {
    @Bindable var viewModel: OnboardingViewModel

    @State private var contentAppeared = false
    @State private var goalsAppeared = false

    private var availableIncome: Decimal {
        let expenses = viewModel.expenses.reduce(0) { $0 + $1.amount }
        return max(0, viewModel.monthlyIncome - expenses)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: Spacing.xl) {
                header
                goalsSection
                divider
                allocationSection
                savingsPreview
                actionButtons
            }
            .padding(Spacing.lg)
        }
        .onAppear {
            triggerAnimations()
        }
    }
}

// MARK: - Header

private extension SavingsGoalsScreen {
    var header: some View {
        OnboardingHeader(
            icon: "target",
            iconColor: DiamerisColors.accentSecondary,
            title: "Let's build your savings plan".localized,
            subtitle: "Your goals fill in priority order. When one completes, money flows to the next!".localized
        )
    }
}

// MARK: - Goals Section

private extension SavingsGoalsScreen {
    var goalsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            goalsSectionTitle
            goalCards
            goalsExplanation
        }
        .opacity(contentAppeared ? 1 : 0)
    }

    var goalsSectionTitle: some View {
        Text("Your Goals".localized)
            .font(.headline)
            .opacity(goalsAppeared ? 1 : 0)
    }

    var goalCards: some View {
        ForEach(Array(viewModel.savingsGoals.enumerated()), id: \.element.id) { index, goal in
            GoalCard(
                goal: goal,
                monthlyIncome: viewModel.monthlyIncome,
                currency: viewModel.currency.rawValue,
                isEditable: true
            ) { newBalance in
                viewModel.savingsGoals[index].currentBalance = newBalance
            }
            .opacity(goalsAppeared ? 1 : 0)
            .offset(y: goalsAppeared ? 0 : SlideOffset.small)
            .animation(
                SpringPreset.responsive.delay(Double(index) * StaggerDelay.standard),
                value: goalsAppeared
            )
        }
    }

    var goalsExplanation: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "info.circle")
                .font(.caption)
                .foregroundStyle(DiamerisColors.accentSecondary)

            Text("Emergency fund fills first, then regular savings".localized)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.top, Spacing.xs)
        .opacity(goalsAppeared ? 1 : 0)
    }
}

// MARK: - Divider

private extension SavingsGoalsScreen {
    var divider: some View {
        Divider()
            .padding(.vertical, Spacing.sm)
            .opacity(contentAppeared ? 1 : 0)
    }
}

// MARK: - Allocation Section

private extension SavingsGoalsScreen {
    var allocationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("How much to save?".localized)
                .font(.headline)

            SavingsSlider(
                percentage: $viewModel.savingsAllocation.percentage,
                availableIncome: availableIncome,
                currency: viewModel.currency.rawValue
            )

            boostToggleCard
        }
        .opacity(contentAppeared ? 1 : 0)
        .offset(y: contentAppeared ? 0 : SlideOffset.small)
    }

    var boostToggleCard: some View {
        VStack(spacing: Spacing.sm) {
            boostToggle
            boostWarning
        }
        .padding(Spacing.md)
        .glassCard()
    }

    var boostToggle: some View {
        Toggle(isOn: $viewModel.savingsAllocation.boostEnabled) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(viewModel.savingsAllocation.boostEnabled ? .yellow : .secondary)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Savings Boost".localized)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("Triple your savings temporarily".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .tint(DiamerisColors.accentPrimary)
        .onChange(of: viewModel.savingsAllocation.boostEnabled) { _, _ in
            HapticManager.lightTap()
        }
    }

    @ViewBuilder
    var boostWarning: some View {
        if viewModel.savingsAllocation.boostEnabled {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)

                Text("Boost is great for catching up, but not sustainable long-term".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(Spacing.sm)
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
        }
    }
}

// MARK: - Savings Preview

private extension SavingsGoalsScreen {
    @ViewBuilder
    var savingsPreview: some View {
        if viewModel.monthlyIncome > 0 {
            let savingsAmount = viewModel.savingsAllocation.calculateSavings(availableIncome: availableIncome)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("This month's savings".localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    Text(AmountFormatter.formatForDisplay(savingsAmount, currency: viewModel.currency.rawValue))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(DiamerisColors.accentSecondary)

                    Text("going to your goals".localized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)
            .background(DiamerisColors.accentSecondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            .opacity(contentAppeared ? 1 : 0)
        }
    }
}

// MARK: - Action Buttons

private extension SavingsGoalsScreen {
    var actionButtons: some View {
        VStack(spacing: Spacing.sm) {
            OnboardingButton("Continue".localized, isEnabled: viewModel.canAdvance) {
                viewModel.advance()
            }

            OnboardingSecondaryButton("Skip for now".localized) {
                viewModel.savingsGoals = SavingsGoalEntry.defaults
                viewModel.savingsAllocation = SavingsAllocationEntry()
                viewModel.advance()
            }
        }
        .padding(.top, Spacing.xl)
    }
}

// MARK: - Animations

private extension SavingsGoalsScreen {
    func triggerAnimations() {
        withAnimation(SpringPreset.smooth.delay(StaggerDelay.initial)) {
            contentAppeared = true
        }

        withAnimation(SpringPreset.responsive.delay(StaggerDelay.initial + AnimationDuration.fast)) {
            goalsAppeared = true
        }
    }
}

#Preview {
    let vm = OnboardingViewModel()
    vm.name = "Vlad"
    vm.monthlyIncome = 14303
    return SavingsGoalsScreen(viewModel: vm)
}
