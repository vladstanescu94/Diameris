import SwiftUI
import DesignSystem

struct ExpensesScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var contentAppeared = false
    @State private var rowsAppeared: [Bool] = [false, false, false]

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            OnboardingHeader(
                icon: "creditcard.fill",
                iconColor: DiamerisColors.accentPrimaryLight,
                title: String(localized: "Let's estimate your main expenses"),
                subtitle: String(localized: "Enter your typical monthly spending. You can skip this and add expenses later.")
            )

            GlassEffectContainer {
                VStack(spacing: Spacing.sm) {
                    ForEach(Array(viewModel.expenses.enumerated()), id: \.element.id) { index, expense in
                        ExpenseRow(
                            icon: expense.icon,
                            name: expense.name,
                            amount: $viewModel.expenses[index].amount,
                            currency: viewModel.currency
                        )
                        .opacity(index < rowsAppeared.count && rowsAppeared[index] ? 1 : 0)
                        .offset(x: index < rowsAppeared.count && rowsAppeared[index] ? 0 : SlideOffset.large)
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(String(localized: "Expense categories"))

            Spacer()

            VStack(spacing: Spacing.lg) {
                OnboardingButton("Continue", isEnabled: true) {
                    viewModel.advance()
                }
                .accessibilityHint(String(localized: "Continues to the accounts step"))

                OnboardingSecondaryButton("Skip for now") {
                    for index in viewModel.expenses.indices {
                        viewModel.expenses[index].amount = 0
                    }
                    viewModel.advance()
                }
                .accessibilityHint(String(localized: "Skips expense entry and continues to accounts"))
            }
            .opacity(contentAppeared ? 1 : 0)
            .offset(y: contentAppeared ? 0 : SlideOffset.standard)
        }
        .padding(Spacing.lg)
        .onAppear {
            triggerStaggeredRowAnimations()
            withAnimation(SpringPreset.smooth.delay(AnimationDuration.slow)) {
                contentAppeared = true
            }
        }
    }

    private func triggerStaggeredRowAnimations() {
        for index in 0..<min(viewModel.expenses.count, rowsAppeared.count) {
            withAnimation(SpringPreset.responsive.delay(StaggerDelay.initial + Double(index) * StaggerDelay.standard)) {
                rowsAppeared[index] = true
            }
        }
    }
}

#Preview {
    let vm = OnboardingViewModel()
    vm.name = "Vlad"
    vm.monthlyIncome = 14303
    return ExpensesScreen(viewModel: vm)
}
