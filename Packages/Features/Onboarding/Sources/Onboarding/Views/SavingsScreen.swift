import SwiftUI
import DesignSystem
import SharedUI
import Utilities
import Domain

/// Supports both prioritized (emergency-first) and split (independent amounts) modes.
struct SavingsScreen: View {
    @Bindable var viewModel: OnboardingViewModel

    @State private var contentAppeared = false
    @Namespace private var boostNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .caption) private var flowNumberSize = ComponentSize.flowItemNumber

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: Spacing.xl) {
                header
                allocationModePicker
                allocationSection
                savingsFlowInfo
                savingsPreview
                actionButtons
            }
            .padding(Spacing.lg)
        }
        .onAppear {
            triggerAnimations()
        }
        .onChange(of: viewModel.savingsAllocation.percentage) {
            // Raising the rate past the safe threshold switches boost off.
            withAnimation(reduceMotion ? nil : .bouncy) {
                viewModel.disableBoostIfUnsafe()
            }
        }
    }
}

// MARK: - Header

private extension SavingsScreen {
    var header: some View {
        OnboardingHeader(
            icon: "banknote.fill",
            iconColor: DiamerisColors.accentSecondary,
            title: "How much do you want to save?".localized,
            subtitle: "Savings are calculated from your income after expenses.".localized
        )
    }
}

// MARK: - Allocation Mode Picker

private extension SavingsScreen {
    var allocationModePicker: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Allocation Strategy".localized)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Picker("Allocation Strategy".localized, selection: $viewModel.savingsAllocation.allocationMode) {
                ForEach(AllocationMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Text(viewModel.savingsAllocation.allocationMode.description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .entrance(contentAppeared, y: SlideOffset.small)
    }
}

// MARK: - Allocation Section

private extension SavingsScreen {
    @ViewBuilder
    var allocationSection: some View {
        switch viewModel.savingsAllocation.allocationMode {
        case .prioritized:
            prioritizedSection
        case .split:
            splitSection
        }
    }

    var prioritizedSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Monthly Savings".localized)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Picker("Savings Type".localized, selection: $viewModel.savingsAllocation.savingsInputMode) {
                ForEach(SavingsInputMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if viewModel.savingsAllocation.savingsInputMode == .percentage {
                SavingsSlider(
                    percentage: $viewModel.savingsAllocation.percentage,
                    savingsAmount: viewModel.savingsAllocation.calculateSavings(availableIncome: viewModel.availableIncome),
                    currency: viewModel.currency.rawValue
                )

                boostToggleCard
            } else {
                CurrencyAmountField(
                    amount: $viewModel.savingsAllocation.fixedAmount,
                    currency: $viewModel.currency,
                    showCurrencyPicker: false,
                    accessibilityLabel: "Monthly Savings".localized
                )
            }
        }
        .entrance(contentAppeared, y: SlideOffset.small)
    }

    var splitSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Monthly Amounts".localized)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            if viewModel.hasEmergencyAccount {
                SplitAmountInput(
                    title: "Emergency Fund".localized,
                    icon: AccountType.emergency.icon,
                    inputMode: $viewModel.savingsAllocation.splitEmergencyInputMode,
                    percentage: $viewModel.savingsAllocation.splitEmergencyPercentage,
                    amount: $viewModel.savingsAllocation.splitEmergencyAmount,
                    currency: $viewModel.currency,
                    resolvedAmount: viewModel.savingsAllocation.resolvedSplitEmergencyAmount(availableIncome: viewModel.availableIncome)
                )
            }

            if viewModel.hasPrimarySavingsAccount {
                SplitAmountInput(
                    title: "Savings".localized,
                    icon: AccountType.savings.icon,
                    inputMode: $viewModel.savingsAllocation.splitSavingsInputMode,
                    percentage: $viewModel.savingsAllocation.splitSavingsPercentage,
                    amount: $viewModel.savingsAllocation.splitSavingsAmount,
                    currency: $viewModel.currency,
                    resolvedAmount: viewModel.savingsAllocation.resolvedSplitSavingsAmount(availableIncome: viewModel.availableIncome)
                )
            }

            if !viewModel.hasEmergencyAccount && !viewModel.hasPrimarySavingsAccount {
                Text("Add an emergency or savings account first to use split mode.".localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Spacing.md)
            }
        }
        .entrance(contentAppeared, y: SlideOffset.small)
    }
}

// MARK: - Boost Toggle Card

private extension SavingsScreen {
    var boostToggleCard: some View {
        // GlassEffectContainer enables morphing when warning appears/disappears
        GlassEffectContainer(spacing: 0) {
            VStack(spacing: Spacing.sm) {
                boostToggle

                if viewModel.savingsAllocation.boostEnabled {
                    boostWarning
                }
            }
            .padding(Spacing.md)
            .glassEffect(in: .rect(cornerRadius: CornerRadius.large))
            .glassEffectID("boostCard", in: boostNamespace)
        }
    }

    var boostToggle: some View {
        Toggle(isOn: $viewModel.isBoostEnabled.animation(reduceMotion ? nil : .bouncy)) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(viewModel.savingsAllocation.boostEnabled ? .yellow : .secondary)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Savings Boost".localized)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(boostDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .tint(DiamerisColors.accentPrimary)
        .disabled(!viewModel.canEnableBoost && !viewModel.savingsAllocation.boostEnabled)
        .onChange(of: viewModel.savingsAllocation.boostEnabled) {
            HapticManager.lightTap()
        }
    }

    var boostDescription: String {
        if viewModel.canEnableBoost {
            return "Triple your savings temporarily".localized
        } else {
            return "Lower your savings rate to enable boost".localized
        }
    }

    var boostWarning: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.caption)
                .foregroundStyle(.orange)
                .accessibilityHidden(true)

            Text("Boost is great for catching up, but not sustainable long-term".localized)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.sm)
        .background(Color.orange.opacity(Opacity.faint))
        .clipShape(.rect(cornerRadius: CornerRadius.small))
    }
}

// MARK: - Savings Flow Info

private extension SavingsScreen {
    @ViewBuilder
    var savingsFlowInfo: some View {
        if viewModel.hasEmergencyAccount || viewModel.hasPrimarySavingsAccount {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundStyle(DiamerisColors.accentSecondary)
                        .accessibilityHidden(true)

                    Text("How your savings are distributed".localized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .accessibilityAddTraits(.isHeader)
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    if viewModel.savingsAllocation.allocationMode == .prioritized {
                        prioritizedFlowItems
                    } else {
                        splitFlowItems
                    }
                }
            }
            .padding(Spacing.md)
            .glassCard()
            .opacity(contentAppeared ? 1 : 0)
        }
    }

    @ViewBuilder
    var prioritizedFlowItems: some View {
        if viewModel.hasEmergencyAccount {
            flowItem(
                number: 1,
                text: "Emergency fund fills first until target reached".localized,
                icon: "shield.fill"
            )
            .transition(.opacity.animation(.easeOut(duration: AnimationDuration.appear)))
        }

        if viewModel.hasPrimarySavingsAccount {
            flowItem(
                number: viewModel.hasEmergencyAccount ? 2 : 1,
                text: "Remaining savings go to your savings account".localized,
                icon: "banknote.fill"
            )
            .transition(.opacity.animation(.easeOut(duration: AnimationDuration.appear)))
        }
    }

    @ViewBuilder
    var splitFlowItems: some View {
        if viewModel.hasEmergencyAccount {
            let emergencyText = viewModel.savingsAllocation.splitEmergencyInputMode == .percentage
                ? "Percentage of income after expenses to emergency each month".localized
                : "Fixed amount to emergency each month".localized
            flowItem(
                number: 1,
                text: emergencyText,
                icon: "shield.fill"
            )
            .transition(.opacity.animation(.easeOut(duration: AnimationDuration.appear)))
        }

        if viewModel.hasPrimarySavingsAccount {
            let savingsText = viewModel.savingsAllocation.splitSavingsInputMode == .percentage
                ? "Percentage of income after expenses to savings each month".localized
                : "Fixed amount to savings each month".localized
            flowItem(
                number: viewModel.hasEmergencyAccount ? 2 : 1,
                text: savingsText,
                icon: "banknote.fill"
            )
            .transition(.opacity.animation(.easeOut(duration: AnimationDuration.appear)))
        }
    }

    func flowItem(number: Int, text: String, icon: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Text(number, format: .number)
                .font(.caption)
                .bold()
                .frame(width: flowNumberSize, height: flowNumberSize)
                .background(DiamerisColors.accentSecondary.opacity(Opacity.light))
                .clipShape(Circle())

            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(DiamerisColors.accentSecondary)
                .accessibilityHidden(true)

            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Savings Preview

private extension SavingsScreen {
    @ViewBuilder
    var savingsPreview: some View {
        // What the transfer plan actually routes to savings accounts (Domain calculation).
        let savingsAmount = viewModel.transferPlan.totalSavings

        if savingsAmount > 0 {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("This month's savings".localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ViewThatFits(in: .horizontal) {
                    HStack { savingsPreviewAmount(savingsAmount) }
                    VStack(alignment: .leading) { savingsPreviewAmount(savingsAmount) }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)
            .background(DiamerisColors.accentSecondary.opacity(Opacity.faint))
            .clipShape(.rect(cornerRadius: CornerRadius.medium))
            .accessibilityElement(children: .combine)
            .opacity(contentAppeared ? 1 : 0)
        }
    }

    @ViewBuilder
    func savingsPreviewAmount(_ amount: Decimal) -> some View {
        Text(AmountFormatter.formatForDisplay(amount, currency: viewModel.currency.rawValue))
            .font(.title2)
            .bold()

        Text("going to your accounts".localized)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }
}

// MARK: - Action Buttons

private extension SavingsScreen {
    var actionButtons: some View {
        VStack(spacing: Spacing.sm) {
            OnboardingButton("Continue".localized, isEnabled: viewModel.canAdvance) {
                viewModel.advance()
            }
            .accessibilityHint("Continues to your transfer plan".localized)

            OnboardingSecondaryButton("Skip for now".localized) {
                viewModel.savingsAllocation = SavingsAllocationEntry()
                viewModel.advance()
            }
        }
        .padding(.top, Spacing.xl)
    }
}

// MARK: - Animations

private extension SavingsScreen {
    func triggerAnimations() {
        withAnimation(SpringPreset.smooth.delay(StaggerDelay.initial)) {
            contentAppeared = true
        }
    }
}

#Preview {
    let vm = OnboardingViewModel()
    vm.name = "Vlad"
    vm.monthlyIncome = 14303
    vm.accounts = [
        .primary(),
        .emergency(multiplier: 3.0),
        .savings(isPrimarySavings: true)
    ]
    return SavingsScreen(viewModel: vm)
}
