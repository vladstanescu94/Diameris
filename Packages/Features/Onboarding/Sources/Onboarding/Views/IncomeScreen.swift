import SwiftUI
import DesignSystem
import SharedUI
import Utilities

struct IncomeScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    @FocusState private var isAmountFocused: Bool
    @State private var contentAppeared = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            header
            incomeInputSection
            helperText
            Spacer()
            continueButton
        }
        .padding(Spacing.lg)
        .onAppear { triggerAnimations() }
    }
}

// MARK: - Subviews

private extension IncomeScreen {
    var header: some View {
        OnboardingHeader(
            icon: "banknote.fill",
            iconColor: DiamerisColors.accentSecondary,
            title: String(localized: "Nice to meet you, \(viewModel.trimmedName)!", bundle: .module),
            subtitle: "How much lands in your account each month after taxes?".localized
        )
    }

    var incomeInputSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Monthly net income".localized)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            CurrencyAmountField(
                amount: $viewModel.monthlyIncome,
                currency: $viewModel.currency
            )
            .accessibilityLabel("Monthly income amount".localized)
        }
        .opacity(contentAppeared ? 1 : 0)
        .offset(y: contentAppeared ? 0 : SlideOffset.standard)
    }

    var helperText: some View {
        Text("This is your starting point — we'll help you decide where every unit goes.".localized)
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .opacity(contentAppeared ? 1 : 0)
    }

    var continueButton: some View {
        OnboardingButton("Continue".localized, isEnabled: viewModel.canAdvance) {
            viewModel.advance()
        }
        .opacity(contentAppeared ? 1 : 0)
        .offset(y: contentAppeared ? 0 : SlideOffset.standard)
        .accessibilityHint("Continues to the expenses step".localized)
    }
}

// MARK: - Animations

private extension IncomeScreen {
    func triggerAnimations() {
        withAnimation(SpringPreset.smooth.delay(StaggerDelay.initial)) {
            contentAppeared = true
        }
    }
}

#Preview {
    let vm = OnboardingViewModel()
    vm.name = "Vlad"
    return IncomeScreen(viewModel: vm)
}
