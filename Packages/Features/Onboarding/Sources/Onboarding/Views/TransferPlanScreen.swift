import SwiftUI
import DesignSystem
import SharedUI
import Utilities

/// The payoff screen - shows the user's personalized transfer plan.
struct TransferPlanScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    let onComplete: () -> Void

    @State private var showCelebration = false
    @State private var headerAppeared = false
    @State private var incomeAppeared = false
    @State private var transfersAppeared = false
    @State private var remainingAppeared = false
    @State private var verificationAppeared = false

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
                transferCardsSection
                remainingMoneySection
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

            Text("Your First Month".localized)
                .font(.largeTitle)
                .fontWeight(.bold)
                .opacity(headerAppeared ? 1 : 0)
                .offset(y: headerAppeared ? 0 : SlideOffset.small)

            Text(String(localized: "Here's your personalized transfer plan, \(viewModel.trimmedName)!", bundle: .module))
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
        .opacity(incomeAppeared ? 1 : 0)
        .scaleEffect(incomeAppeared ? 1 : 0.95)
    }
}

// MARK: - Transfer Cards Section

private extension TransferPlanScreen {
    var transferCardsSection: some View {
        VStack(spacing: Spacing.md) {
            sectionHeader
            accountAllocationCards
            expenseTransferCards
            primaryAccountCard
        }
    }

    var sectionHeader: some View {
        Text("Your Transfers".localized)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(transfersAppeared ? 1 : 0)
    }

    var accountAllocationCards: some View {
        ForEach(Array(transferPlan.accountAllocations.enumerated()), id: \.element.id) { index, allocation in
            AccountAllocationCard(
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

    var expenseTransferCards: some View {
        ForEach(Array(transferPlan.accountExpenseTransfers.enumerated()), id: \.element.id) { index, transfer in
            ExpenseTransferCard(
                transfer: transfer,
                currency: viewModel.currency.rawValue
            )
            .opacity(transfersAppeared ? 1 : 0)
            .offset(x: transfersAppeared ? 0 : SlideOffset.standard)
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
        .opacity(transfersAppeared ? 1 : 0)
        .offset(x: transfersAppeared ? 0 : SlideOffset.standard)
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
            VStack(spacing: Spacing.md) {
                Text("Remaining Money".localized)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                remainingMoneyCard
                remainingDestinationPicker
            }
            .opacity(remainingAppeared ? 1 : 0)
            .offset(y: remainingAppeared ? 0 : SlideOffset.small)
        }
    }

    var remainingMoneyCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundStyle(.green)

                Text("Available after savings".localized)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text(AmountFormatter.formatForDisplay(transferPlan.remainingMoney, currency: viewModel.currency.rawValue))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.green)
            }
        }
        .padding(Spacing.md)
        .glassCard()
    }

    var remainingDestinationPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Where should this go?".localized)
                .font(.caption)
                .foregroundStyle(.secondary)

            RemainingMoneyPicker(
                selectedDestination: $viewModel.remainingMoneyDestination,
                hasSavingsAccount: viewModel.hasPrimarySavingsAccount,
                hasPersonalAccount: viewModel.personalAccount != nil
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

            Text(String(localized: "Total: \(AmountFormatter.formatForDisplay(transferPlan.income, currency: viewModel.currency.rawValue))", bundle: .module))
                .font(.subheadline)
                .fontWeight(.medium)

            if transferPlan.isBalanced {
                Text("All accounted for!".localized)
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

            Text("Tip: Do these transfers right after payday for best results!".localized)
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
        OnboardingButton("Start Using Diameris".localized, isEnabled: true) {
            HapticManager.success()
            onComplete()
        }
        .padding(.top, Spacing.xl)
        .padding(.bottom, Spacing.lg)
    }
}

// MARK: - Animations

private extension TransferPlanScreen {
    /// Total number of transfer cards for animation timing
    private var totalTransferCards: Int {
        transferPlan.accountAllocations.count +
        transferPlan.accountExpenseTransfers.count +
        1 // Primary account card
    }

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
                        .foregroundStyle(allocation.isComplete ? .green : .orange)

                    if allocation.isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)

                        Text("Target reached!".localized)
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }

            if allocation.accountType == .emergency, let target = allocation.targetAmount {
                ProgressView(value: allocation.progressAfter ?? 0)
                    .tint(allocation.isComplete ? .green : .orange)

                Text(String(localized: "Target: \(AmountFormatter.formatForDisplay(target, currency: currency))", bundle: .module))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Spacing.md)
        .glassCard()
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

                Text(transfer.accountName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text(AmountFormatter.formatForDisplay(transfer.amount, currency: currency))
                    .font(.headline)
                    .fontWeight(.bold)
            }

            Text(transfer.expenseNames.joined(separator: ", "))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.md)
        .glassCard()
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
