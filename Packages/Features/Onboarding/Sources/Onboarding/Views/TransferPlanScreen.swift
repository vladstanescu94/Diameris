import SwiftUI
import DesignSystem
import SharedUI
import Utilities
import Domain

/// Final step: the first month's personalized transfer plan.
struct TransferPlanScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    let onComplete: () -> Void

    @State private var showCelebration = false
    @State private var headerAppeared = false
    @State private var incomeAppeared = false
    @State private var transfersAppeared = false
    @State private var remainingAppeared = false
    @State private var verificationAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var transferPlan: TransferPlan {
        viewModel.transferPlan
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
                shortfallWarning
                transferCardsSection
                remainingMoneySection
                verificationRow
                tipRow
                completeButton
            }
            .padding(.horizontal, Spacing.lg)
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    var celebrationOverlay: some View {
        // Confetti and expanding rings are large motion; skip them with Reduce Motion.
        if showCelebration && !reduceMotion {
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
                .entrance(headerAppeared, scale: 0.5)

            Text("Your First Month".localized)
                .font(.largeTitle)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)
                .entrance(headerAppeared, y: SlideOffset.small)

            Text(String(localized: "Here's your personalized transfer plan, \(viewModel.trimmedName)!", bundle: .module))
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .entrance(headerAppeared, y: SlideOffset.subtle)
        }
        .padding(.top, Spacing.lg)
    }
}

// MARK: - Income Hero Card

private extension TransferPlanScreen {
    var incomeHeroCard: some View {
        VStack(spacing: Spacing.xs) {
            Text("Monthly Income".localized)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(AmountFormatter.formatForDisplay(transferPlan.income, currency: viewModel.currency.rawValue))
                .font(.largeTitle)
                .fontWeight(.bold)
                .fontDesign(.rounded)
                .foregroundStyle(DiamerisColors.accentSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .glassCard()
        .entrance(incomeAppeared, scale: 0.95)
    }
}

// MARK: - Shortfall Warning

private extension TransferPlanScreen {
    @ViewBuilder
    var shortfallWarning: some View {
        if transferPlan.shortfall > 0 {
            HStack(alignment: .top, spacing: Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(String(
                        localized: "Your expenses are \(AmountFormatter.formatForDisplay(transferPlan.shortfall, currency: viewModel.currency.rawValue)) more than your income",
                        bundle: .module
                    ))
                    .font(.subheadline)
                    .fontWeight(.medium)

                    Text("No savings can be planned until expenses fit. You can adjust them anytime in the Expenses tab.".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(Opacity.faint))
            .clipShape(.rect(cornerRadius: CornerRadius.medium))
            .accessibilityElement(children: .combine)
            .entrance(incomeAppeared, scale: ScaleEffect.pressed)
        }
    }
}

// MARK: - Transfer Cards Section

private extension TransferPlanScreen {
    var transferCardsSection: some View {
        GlassEffectContainer(spacing: Spacing.md) {
            VStack(spacing: Spacing.md) {
                sectionHeader
                accountAllocationCards
                expenseTransferCards
                primaryAccountCard
            }
        }
    }

    var sectionHeader: some View {
        Text("Your Transfers".localized)
            .font(.headline)
            .accessibilityAddTraits(.isHeader)
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(transfersAppeared ? 1 : 0)
    }

    var accountAllocationCards: some View {
        ForEach(transferPlan.accountAllocations.enumerated(), id: \.element.accountId) { index, allocation in
            AccountAllocationCard(
                allocation: allocation,
                currency: viewModel.currency.rawValue
            )
            .entrance(transfersAppeared, x: SlideOffset.standard)
            .animation(
                SpringPreset.responsive.delay(Double(index) * StaggerDelay.standard),
                value: transfersAppeared
            )
        }
    }

    var expenseTransferCards: some View {
        ForEach(transferPlan.accountExpenseTransfers.enumerated(), id: \.element.accountId) { index, transfer in
            ExpenseTransferCard(
                transfer: transfer,
                currency: viewModel.currency.rawValue
            )
            .entrance(transfersAppeared, x: SlideOffset.standard)
            .animation(
                SpringPreset.responsive.delay(Double(transferPlan.accountAllocations.count + index) * StaggerDelay.standard),
                value: transfersAppeared
            )
        }
    }

    var primaryAccountCard: some View {
        let cardIndex = transferPlan.accountAllocations.count + transferPlan.accountExpenseTransfers.count

        return VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "building.columns.fill")
                    .foregroundStyle(DiamerisColors.accentPrimary)
                    .accessibilityHidden(true)

                Text("Stays in Primary".localized)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text(AmountFormatter.formatForDisplay(transferPlan.remainsInPrimary, currency: viewModel.currency.rawValue))
                    .font(.headline)
                    .fontWeight(.bold)
            }

            Text("For automatic bill payments".localized)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.md)
        .glassCard()
        .accessibilityElement(children: .combine)
        .entrance(transfersAppeared, x: SlideOffset.standard)
        .animation(
            SpringPreset.responsive.delay(Double(cardIndex) * StaggerDelay.standard),
            value: transfersAppeared
        )
    }
}

// MARK: - Remaining Money Section

private extension TransferPlanScreen {
    @ViewBuilder
    var remainingMoneySection: some View {
        if transferPlan.remainingMoney > 0 {
            GlassEffectContainer(spacing: Spacing.md) {
                VStack(spacing: Spacing.md) {
                    Text("Remaining Money".localized)
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    remainingMoneyCard
                    remainingDestinationPicker
                }
            }
            .entrance(remainingAppeared, y: SlideOffset.small)
        }
    }

    var remainingMoneyCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundStyle(.green)
                    .accessibilityHidden(true)

                Text("Available after savings".localized)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text(AmountFormatter.formatForDisplay(transferPlan.remainingMoney, currency: viewModel.currency.rawValue))
                    .font(.headline)
                    .fontWeight(.bold)
            }
        }
        .padding(Spacing.md)
        .glassCard()
        .accessibilityElement(children: .combine)
    }

    var remainingDestinationPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Where should this go?".localized)
                .font(.caption)
                .foregroundStyle(.secondary)

            RemainingMoneyPicker(
                selectedDestination: $viewModel.remainingMoneyDestination,
                destinations: viewModel.availableRemainingDestinations
            )
        }
    }
}

// MARK: - Verification & Tip

private extension TransferPlanScreen {
    var verificationRow: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: transferPlan.isBalanced ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(transferPlan.isBalanced ? .green : .orange)
                .accessibilityLabel(transferPlan.isBalanced ? "" : "Totals don't match".localized)
                .accessibilityHidden(transferPlan.isBalanced)

            Text(String(localized: "Total: \(AmountFormatter.formatForDisplay(transferPlan.income, currency: viewModel.currency.rawValue))", bundle: .module))
                .font(.subheadline)
                .fontWeight(.medium)

            if transferPlan.isBalanced {
                Text("All accounted for!".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .transition(.opacity.animation(.easeOut(duration: AnimationDuration.appear)))
            }
        }
        .accessibilityElement(children: .combine)
        .padding(Spacing.md)
        .frame(maxWidth: .infinity)
        .background(transferPlan.isBalanced ? Color.green.opacity(Opacity.faint) : Color.orange.opacity(Opacity.faint))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        .entrance(verificationAppeared, scale: 0.95)
    }

    var tipRow: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(.yellow)
                .accessibilityHidden(true)

            Text("Tip: Do these transfers right after payday for best results!".localized)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(verificationAppeared ? 1 : 0)
    }
}

// MARK: - Complete Button

private extension TransferPlanScreen {
    var completeButton: some View {
        OnboardingButton("Start Using Diameris".localized, isEnabled: !viewModel.hasCompleted) {
            guard !viewModel.hasCompleted else { return }
            HapticManager.success()
            onComplete()
        }
        .padding(.top, Spacing.xl)
        .padding(.bottom, Spacing.lg)
    }
}

// MARK: - Animations

private extension TransferPlanScreen {
    private var totalTransferCards: Int {
        transferPlan.accountAllocations.count +
        transferPlan.accountExpenseTransfers.count +
        1 // "Stays in Primary" card
    }

    func triggerAnimations() {
        // CompletionCelebration plays the success haptic itself.
        showCelebration = true

        withAnimation(SpringPreset.bouncy.delay(StaggerDelay.initial)) {
            headerAppeared = true
        }

        withAnimation(SpringPreset.smooth.delay(AnimationDuration.fast)) {
            incomeAppeared = true
        }

        withAnimation(SpringPreset.responsive.delay(AnimationDuration.medium)) {
            transfersAppeared = true
        }

        withAnimation(SpringPreset.smooth.delay(AnimationDuration.slow + Double(totalTransferCards) * StaggerDelay.standard)) {
            remainingAppeared = true
        }

        withAnimation(SpringPreset.smooth.delay(AnimationDuration.slow + Double(totalTransferCards + 1) * StaggerDelay.standard)) {
            verificationAppeared = true
        }
    }
}

// MARK: - Account Allocation Card

private struct AccountAllocationCard: View {
    let allocation: TransferPlan.AccountAllocation
    let currency: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: allocation.icon)
                    .foregroundStyle(allocation.accountType.color)
                    .accessibilityHidden(true)

                Text(allocation.accountName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text(AmountFormatter.formatForDisplay(allocation.amount, currency: currency))
                    .font(.headline)
                    .fontWeight(.bold)
            }

            if let progressDisplay = allocation.progressChangeDisplay {
                HStack {
                    Text(progressDisplay)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())

                    if allocation.isComplete {
                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                                .accessibilityHidden(true)

                            Text("Target reached!".localized)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .transition(.opacity.animation(.easeOut(duration: AnimationDuration.appear)))
                    }
                }
                .transition(.opacity.animation(.easeOut(duration: AnimationDuration.appear)))
            }

            if allocation.accountType == .emergency, let target = allocation.targetAmount {
                ProgressView(value: allocation.progressAfter ?? 0)
                    .tint(allocation.isComplete ? .green : .orange)
                    .animation(.easeOut(duration: AnimationDuration.appear), value: allocation.progressAfter)

                Text(String(localized: "Target: \(AmountFormatter.formatForDisplay(target, currency: currency))", bundle: .module))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Spacing.md)
        .glassCard()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Expense Transfer Card

private struct ExpenseTransferCard: View {
    let transfer: TransferPlan.AccountExpenseTransfer
    let currency: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundStyle(.purple)
                    .accessibilityHidden(true)

                Text(String.localized("Transfer to \(transfer.accountName)"))
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text(AmountFormatter.formatForDisplay(transfer.amount, currency: currency))
                    .font(.headline)
                    .fontWeight(.bold)
            }

            Text(String.localized("for \(transfer.expenseNames.formatted(.list(type: .and)))"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.md)
        .glassCard()
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let vm = OnboardingViewModel()
    vm.name = "Vlad"
    vm.monthlyIncome = 14303
    vm.expenses[0].amount = 3000
    vm.expenses[2].amount = 300
    vm.accounts = [
        .primary(),
        .emergency(multiplier: 3.0, currentBalance: 37056),
        .savings(isPrimarySavings: true)
    ]
    return TransferPlanScreen(viewModel: vm, onComplete: {})
}
