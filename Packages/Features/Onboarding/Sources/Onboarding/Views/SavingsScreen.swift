import SwiftUI
import DesignSystem
import SharedUI
import Utilities
import Domain

/// Screen for setting up savings allocation.
/// Supports both prioritized (emergency-first) and split (independent amounts) modes.
struct SavingsScreen: View {
    @Bindable var viewModel: OnboardingViewModel

    @State private var contentAppeared = false
    @Namespace private var boostNamespace

    private var availableIncome: Decimal {
        let expenses = viewModel.expenses.reduce(0) { $0 + $1.amount }
        return max(0, viewModel.monthlyIncome - expenses)
    }

    /// Check if enabling boost would exceed available income
    private var canEnableBoost: Bool {
        let effectivePercentage = viewModel.savingsAllocation.percentage * viewModel.savingsAllocation.boostMultiplier
        return effectivePercentage <= 1.0
    }

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
        .onChange(of: viewModel.savingsAllocation.percentage) { _, _ in
            // Auto-disable boost if percentage increases beyond threshold
            if viewModel.savingsAllocation.boostEnabled && !canEnableBoost {
                withAnimation(.bouncy) {
                    viewModel.savingsAllocation.boostEnabled = false
                }
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
        .opacity(contentAppeared ? 1 : 0)
        .offset(y: contentAppeared ? 0 : SlideOffset.small)
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

            // Input mode toggle
            Picker("Savings Type".localized, selection: $viewModel.savingsAllocation.savingsInputMode) {
                ForEach(SavingsInputMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if viewModel.savingsAllocation.savingsInputMode == .percentage {
                SavingsSlider(
                    percentage: $viewModel.savingsAllocation.percentage,
                    availableIncome: availableIncome,
                    currency: viewModel.currency.rawValue,
                    boostEnabled: viewModel.savingsAllocation.boostEnabled,
                    boostMultiplier: viewModel.savingsAllocation.boostMultiplier
                )

                boostToggleCard
            } else {
                fixedAmountInput
            }
        }
        .opacity(contentAppeared ? 1 : 0)
        .offset(y: contentAppeared ? 0 : SlideOffset.small)
    }

    var fixedAmountInput: some View {
        VStack(spacing: Spacing.md) {
            CurrencyAmountField(
                amount: $viewModel.savingsAllocation.fixedAmount,
                currency: $viewModel.currency,
                showCurrencyPicker: false
            )
        }
    }

    var splitSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Monthly Amounts".localized)
                .font(.headline)

            if viewModel.hasEmergencyAccount {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Label("Emergency Fund".localized, systemImage: AccountType.emergency.icon)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Picker("Emergency Fund".localized, selection: $viewModel.savingsAllocation.splitEmergencyInputMode) {
                        ForEach(SavingsInputMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    if viewModel.savingsAllocation.splitEmergencyInputMode == .percentage {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack {
                                Text("\(Int(viewModel.savingsAllocation.splitEmergencyPercentage * 100))%")
                                    .font(.title3)
                                    .bold()
                                    .foregroundStyle(DiamerisColors.accentSecondary)
                                    .monospacedDigit()
                                Spacer()
                                if availableIncome > 0 {
                                    let amount = availableIncome * Decimal(viewModel.savingsAllocation.splitEmergencyPercentage)
                                    Text(AmountFormatter.formatForDisplay(amount, currency: viewModel.currency.rawValue))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Slider(
                                value: $viewModel.savingsAllocation.splitEmergencyPercentage,
                                in: 0.05...0.50,
                                step: 0.01
                            )
                            .tint(DiamerisColors.accentSecondary)
                        }
                    } else {
                        CurrencyAmountField(
                            amount: $viewModel.savingsAllocation.splitEmergencyAmount,
                            currency: $viewModel.currency,
                            showCurrencyPicker: false
                        )
                    }
                }
            }

            if viewModel.hasPrimarySavingsAccount {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Label("Savings".localized, systemImage: AccountType.savings.icon)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Picker("Savings".localized, selection: $viewModel.savingsAllocation.splitSavingsInputMode) {
                        ForEach(SavingsInputMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    if viewModel.savingsAllocation.splitSavingsInputMode == .percentage {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack {
                                Text("\(Int(viewModel.savingsAllocation.splitSavingsPercentage * 100))%")
                                    .font(.title3)
                                    .bold()
                                    .foregroundStyle(DiamerisColors.accentSecondary)
                                    .monospacedDigit()
                                Spacer()
                                if availableIncome > 0 {
                                    let amount = availableIncome * Decimal(viewModel.savingsAllocation.splitSavingsPercentage)
                                    Text(AmountFormatter.formatForDisplay(amount, currency: viewModel.currency.rawValue))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Slider(
                                value: $viewModel.savingsAllocation.splitSavingsPercentage,
                                in: 0.05...0.50,
                                step: 0.01
                            )
                            .tint(DiamerisColors.accentSecondary)
                        }
                    } else {
                        CurrencyAmountField(
                            amount: $viewModel.savingsAllocation.splitSavingsAmount,
                            currency: $viewModel.currency,
                            showCurrencyPicker: false
                        )
                    }
                }
            }

            if !viewModel.hasEmergencyAccount && !viewModel.hasPrimarySavingsAccount {
                Text("Add an emergency or savings account first to use split mode.".localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Spacing.md)
            }
        }
        .opacity(contentAppeared ? 1 : 0)
        .offset(y: contentAppeared ? 0 : SlideOffset.small)
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
        Toggle(isOn: Binding(
            get: { viewModel.savingsAllocation.boostEnabled },
            set: { newValue in
                // Only allow enabling if boost won't exceed available income
                guard newValue == false || canEnableBoost else { return }
                withAnimation(.bouncy) {
                    viewModel.savingsAllocation.boostEnabled = newValue
                }
                HapticManager.lightTap()
            }
        )) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(viewModel.savingsAllocation.boostEnabled ? .yellow : .secondary)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Savings Boost".localized)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(boostDescription)
                        .font(.caption)
                        .foregroundStyle(canEnableBoost ? Color.secondary : Color.orange)
                }
            }
        }
        .tint(DiamerisColors.accentPrimary)
        .disabled(!canEnableBoost && !viewModel.savingsAllocation.boostEnabled)
    }

    var boostDescription: String {
        if canEnableBoost {
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

            Text("Boost is great for catching up, but not sustainable long-term".localized)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.sm)
        .background(Color.orange.opacity(Opacity.faint))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
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

                    Text("How your savings are distributed".localized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
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
                number: "1",
                text: "Emergency fund fills first until target reached".localized,
                icon: "shield.fill"
            )
            .transition(.opacity.animation(.easeOut(duration: AnimationDuration.appear)))
        }

        if viewModel.hasPrimarySavingsAccount {
            flowItem(
                number: viewModel.hasEmergencyAccount ? "2" : "1",
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
                ? "Percentage of income to emergency each month".localized
                : "Fixed amount to emergency each month".localized
            flowItem(
                number: "1",
                text: emergencyText,
                icon: "shield.fill"
            )
            .transition(.opacity.animation(.easeOut(duration: AnimationDuration.appear)))
        }

        if viewModel.hasPrimarySavingsAccount {
            let savingsText = viewModel.savingsAllocation.splitSavingsInputMode == .percentage
                ? "Percentage of income to savings each month".localized
                : "Fixed amount to savings each month".localized
            flowItem(
                number: viewModel.hasEmergencyAccount ? "2" : "1",
                text: savingsText,
                icon: "banknote.fill"
            )
            .transition(.opacity.animation(.easeOut(duration: AnimationDuration.appear)))
        }
    }

    func flowItem(number: String, text: String, icon: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Text(number)
                .font(.caption)
                .bold()
                .frame(width: ComponentSize.flowItemNumber, height: ComponentSize.flowItemNumber)
                .background(DiamerisColors.accentSecondary.opacity(0.2))
                .clipShape(Circle())

            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(DiamerisColors.accentSecondary)

            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Savings Preview

private extension SavingsScreen {
    @ViewBuilder
    var savingsPreview: some View {
        if viewModel.monthlyIncome > 0 {
            let savingsAmount = calculatePreviewSavings()

            if savingsAmount > 0 {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("This month's savings".localized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack {
                        Text(AmountFormatter.formatForDisplay(savingsAmount, currency: viewModel.currency.rawValue))
                            .font(.title2)
                            .bold()
                            .foregroundStyle(DiamerisColors.accentSecondary)

                        Text("going to your accounts".localized)
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

    func calculatePreviewSavings() -> Decimal {
        switch viewModel.savingsAllocation.allocationMode {
        case .prioritized:
            return viewModel.savingsAllocation.calculateSavings(availableIncome: availableIncome)
        case .split:
            let total = viewModel.savingsAllocation.splitTotal(availableIncome: availableIncome)
            return min(total, availableIncome)
        }
    }
}

// MARK: - Action Buttons

private extension SavingsScreen {
    var actionButtons: some View {
        VStack(spacing: Spacing.sm) {
            OnboardingButton("Continue".localized, isEnabled: viewModel.canAdvance) {
                viewModel.advance()
            }

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
