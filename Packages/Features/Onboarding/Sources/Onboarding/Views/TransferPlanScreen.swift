import SwiftUI
import DesignSystem

/// The payoff screen - shows the user's personalized transfer plan.
struct TransferPlanScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    let onComplete: () -> Void

    @State private var showCelebration = false
    @State private var headerAppeared = false
    @State private var incomeAppeared = false
    @State private var transfersAppeared = false
    @State private var verificationAppeared = false

    private var transferPlan: TransferPlan {
        TransferCalculator.calculate(
            income: viewModel.monthlyIncome,
            expenses: viewModel.expenses,
            goals: viewModel.savingsGoals,
            allocation: viewModel.savingsAllocation,
            accounts: viewModel.allAccounts
        )
    }

    var body: some View {
        ZStack {
            scrollContent
            celebrationOverlay
        }
        .onAppear {
            triggerAnimations()
        }
    }
}

// MARK: - Main Content

private extension TransferPlanScreen {
    var scrollContent: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                headerSection
                incomeHeroCard
                transferCardsSection
                verificationRow
                tipRow
                completeButton
            }
            .padding(.horizontal, Spacing.lg)
        }
    }

    @ViewBuilder
    var celebrationOverlay: some View {
        if showCelebration {
            CompletionCelebration()
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Header Section

private extension TransferPlanScreen {
    var headerSection: some View {
        VStack(spacing: Spacing.md) {
            AnimatedCheckmark()
                .opacity(headerAppeared ? 1 : 0)
                .scaleEffect(headerAppeared ? 1 : 0.5)

            Text(String(localized: "Your First Month"))
                .font(.largeTitle)
                .fontWeight(.bold)
                .opacity(headerAppeared ? 1 : 0)
                .offset(y: headerAppeared ? 0 : SlideOffset.small)

            Text(String(localized: "Here's your personalized transfer plan, \(viewModel.trimmedName)!"))
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .opacity(headerAppeared ? 1 : 0)
                .offset(y: headerAppeared ? 0 : SlideOffset.subtle)
        }
        .padding(.top, Spacing.lg)
    }
}

// MARK: - Income Hero Card

private extension TransferPlanScreen {
    var incomeHeroCard: some View {
        VStack(spacing: Spacing.xs) {
            Text(String(localized: "Monthly Income"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(AmountFormatter.formatForDisplay(transferPlan.income, currency: viewModel.currency.rawValue))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(DiamerisColors.accentSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .glassCard()
        .opacity(incomeAppeared ? 1 : 0)
        .scaleEffect(incomeAppeared ? 1 : 0.95)
    }
}

// MARK: - Transfer Cards Section

private extension TransferPlanScreen {
    var transferCardsSection: some View {
        VStack(spacing: Spacing.md) {
            sectionHeader
            goalAllocationCards
            flexibleSpendingCard
            primaryAccountCard
        }
    }

    var sectionHeader: some View {
        Text(String(localized: "Your Transfers"))
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(transfersAppeared ? 1 : 0)
    }

    var goalAllocationCards: some View {
        ForEach(Array(transferPlan.goalAllocations.enumerated()), id: \.element.id) { index, allocation in
            TransferCard(
                allocation: allocation,
                currency: viewModel.currency.rawValue
            )
            .opacity(transfersAppeared ? 1 : 0)
            .offset(x: transfersAppeared ? 0 : SlideOffset.standard)
            .animation(
                SpringPreset.responsive.delay(Double(index) * StaggerDelay.standard),
                value: transfersAppeared
            )
        }
    }

    @ViewBuilder
    var flexibleSpendingCard: some View {
        if transferPlan.flexibleSpending > 0 {
            TransferCard.flexibleSpending(
                amount: transferPlan.flexibleSpending,
                currency: viewModel.currency.rawValue
            )
            .opacity(transfersAppeared ? 1 : 0)
            .offset(x: transfersAppeared ? 0 : SlideOffset.standard)
            .animation(
                SpringPreset.responsive.delay(Double(transferPlan.goalAllocations.count) * StaggerDelay.standard),
                value: transfersAppeared
            )
        }
    }

    var primaryAccountCard: some View {
        TransferCard.primaryAccount(
            amount: transferPlan.remainsInPrimary,
            currency: viewModel.currency.rawValue
        )
        .opacity(transfersAppeared ? 1 : 0)
        .offset(x: transfersAppeared ? 0 : SlideOffset.standard)
        .animation(
            SpringPreset.responsive.delay(Double(transferPlan.goalAllocations.count + 1) * StaggerDelay.standard),
            value: transfersAppeared
        )
    }
}

// MARK: - Verification & Tip

private extension TransferPlanScreen {
    var verificationRow: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: transferPlan.isBalanced ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(transferPlan.isBalanced ? .green : .orange)

            Text(String(localized: "Total: \(AmountFormatter.formatForDisplay(transferPlan.income, currency: viewModel.currency.rawValue))"))
                .font(.subheadline)
                .fontWeight(.medium)

            if transferPlan.isBalanced {
                Text(String(localized: "All accounted for!"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity)
        .background(transferPlan.isBalanced ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        .opacity(verificationAppeared ? 1 : 0)
        .scaleEffect(verificationAppeared ? 1 : 0.95)
    }

    var tipRow: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(.yellow)

            Text(String(localized: "Tip: Do these transfers right after payday for best results!"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(verificationAppeared ? 1 : 0)
    }
}

// MARK: - Complete Button

private extension TransferPlanScreen {
    var completeButton: some View {
        OnboardingButton("Start Using Diameris", isEnabled: true) {
            HapticManager.success()
            onComplete()
        }
        .padding(.top, Spacing.xl)
        .padding(.bottom, Spacing.lg)
    }
}

// MARK: - Animations

private extension TransferPlanScreen {
    func triggerAnimations() {
        showCelebration = true
        HapticManager.success()

        withAnimation(SpringPreset.bouncy.delay(StaggerDelay.initial)) {
            headerAppeared = true
        }

        withAnimation(SpringPreset.smooth.delay(AnimationDuration.fast)) {
            incomeAppeared = true
        }

        withAnimation(SpringPreset.responsive.delay(AnimationDuration.medium)) {
            transfersAppeared = true
        }

        withAnimation(SpringPreset.smooth.delay(AnimationDuration.slow + Double(transferPlan.goalAllocations.count + 2) * StaggerDelay.standard)) {
            verificationAppeared = true
        }
    }
}

#Preview {
    let vm = OnboardingViewModel()
    vm.name = "Vlad"
    vm.monthlyIncome = 14303
    vm.expenses[0].amount = 3000
    vm.expenses[2].amount = 300
    vm.savingsGoals[0].currentBalance = 37056
    return TransferPlanScreen(viewModel: vm, onComplete: {})
}
