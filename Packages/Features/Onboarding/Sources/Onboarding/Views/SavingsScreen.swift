import SwiftUI
import DesignSystem
import SharedUI
import Utilities

/// Screen for setting up savings allocation percentage.
/// Simplified version - account types now drive savings distribution.
struct SavingsScreen: View {
    @Bindable var viewModel: OnboardingViewModel

    @State private var contentAppeared = false

    private var availableIncome: Decimal {
        let expenses = viewModel.expenses.reduce(0) { $0 + $1.amount }
        return max(0, viewModel.monthlyIncome - expenses)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: Spacing.xl) {
                header
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
    }
}

// MARK: - Header

private extension SavingsScreen {
    var header: some View {
        OnboardingHeader(
            icon: "banknote.fill",
            iconColor: DiamerisColors.accentSecondary,
            title: "How much do you want to save?".localized,
            subtitle: "Set a percentage of your available income to save each month.".localized
        )
    }
}

// MARK: - Allocation Section

private extension SavingsScreen {
    var allocationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Monthly Savings".localized)
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
                    if viewModel.hasEmergencyAccount {
                        flowItem(
                            number: "1",
                            text: "Emergency fund fills first until target reached".localized,
                            icon: "shield.fill"
                        )
                    }

                    if viewModel.hasPrimarySavingsAccount {
                        flowItem(
                            number: viewModel.hasEmergencyAccount ? "2" : "1",
                            text: "Remaining savings go to your savings account".localized,
                            icon: "banknote.fill"
                        )
                    }
                }
            }
            .padding(Spacing.md)
            .glassCard()
            .opacity(contentAppeared ? 1 : 0)
        }
    }

    func flowItem(number: String, text: String, icon: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Text(number)
                .font(.caption)
                .fontWeight(.bold)
                .frame(width: 20, height: 20)
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
