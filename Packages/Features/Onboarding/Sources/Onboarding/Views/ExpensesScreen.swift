import SwiftUI
import DesignSystem
import Utilities
import Domain

struct ExpensesScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var contentAppeared = false
    @State private var rowsAppeared: [Bool] = [false, false, false, false]
    @State private var impactAppeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                header
                expensesList
                impactDisplay
                helperText
                actionButtons
            }
            .padding(Spacing.lg)
        }
        .scrollIndicators(.hidden)
        .onAppear { triggerAnimations() }
    }
}

// MARK: - Computed Properties

private extension ExpensesScreen {
    /// Income left after expenses (Domain calculation via the transfer plan).
    var availableForGoals: Decimal {
        viewModel.availableIncome
    }
}

// MARK: - Subviews

private extension ExpensesScreen {
    var header: some View {
        OnboardingHeader(
            icon: "creditcard.fill",
            iconColor: DiamerisColors.accentPrimary,
            title: "Where does your money go?".localized,
            subtitle: "A quick look at your main expenses. Don't worry about being exact — estimates are fine.".localized
        )
    }

    var expensesList: some View {
        GlassEffectContainer {
            VStack(spacing: Spacing.sm) {
                ForEach(viewModel.expenses.enumerated(), id: \.element.id) { index, expense in
                    ExpenseRow(
                        icon: expense.icon,
                        name: expense.name,
                        amount: $viewModel.expenses[index].amount,
                        currency: viewModel.currency,
                        linkedAccountId: $viewModel.expenses[index].linkedAccountId,
                        accounts: viewModel.accounts
                    )
                    .entrance(index < rowsAppeared.count && rowsAppeared[index], x: SlideOffset.large)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Expense categories".localized)
    }

    @ViewBuilder
    var impactDisplay: some View {
        if viewModel.monthlyIncome > 0 {
            VStack(spacing: Spacing.sm) {
                impactHeader
                impactAmount
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.md)
            .background(availableForGoals > 0 ? DiamerisColors.accentSecondary.opacity(Opacity.faint) : Color.orange.opacity(Opacity.faint))
            .clipShape(.rect(cornerRadius: CornerRadius.medium))
            .accessibilityElement(children: .combine)
            .entrance(impactAppeared, scale: ScaleEffect.pressed)
            .animation(.smooth, value: availableForGoals)
        }
    }

    var impactHeader: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: availableForGoals > 0 ? "arrow.right.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(availableForGoals > 0 ? DiamerisColors.accentSecondary : .orange)
                .accessibilityHidden(true)

            Text("After expenses".localized)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    var impactAmount: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) { impactAmountContent }
            VStack(spacing: Spacing.xxs) { impactAmountContent }
        }
    }

    @ViewBuilder
    var impactAmountContent: some View {
        Text(AmountFormatter.formatForDisplay(availableForGoals, currency: viewModel.currency.rawValue))
            .font(.title2)
            .fontWeight(.bold)
            .contentTransition(.numericText())

        Text("available for your goals".localized)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    var helperText: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "info.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text("By default, expenses are paid from your main account".localized)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .opacity(contentAppeared ? 1 : 0)
    }

    var actionButtons: some View {
        VStack(spacing: Spacing.sm) {
            OnboardingButton("Continue".localized, isEnabled: true) {
                viewModel.advance()
            }
            .accessibilityHint("Continues to the savings step".localized)

            OnboardingSecondaryButton("Skip for now".localized) {
                for index in viewModel.expenses.indices {
                    viewModel.expenses[index].amount = 0
                    viewModel.expenses[index].linkedAccountId = nil
                }
                viewModel.advance()
            }
            .accessibilityHint("Skips expense entry and continues".localized)
        }
        .padding(.top, Spacing.xl)
    }
}

// MARK: - Animations

private extension ExpensesScreen {
    func triggerAnimations() {
        for index in 0..<min(viewModel.expenses.count, rowsAppeared.count) {
            withAnimation(SpringPreset.responsive.delay(StaggerDelay.initial + Double(index) * StaggerDelay.standard)) {
                rowsAppeared[index] = true
            }
        }

        withAnimation(SpringPreset.smooth.delay(AnimationDuration.slow)) {
            contentAppeared = true
        }

        withAnimation(SpringPreset.bouncy.delay(AnimationDuration.slow + StaggerDelay.standard)) {
            impactAppeared = true
        }
    }
}

#Preview {
    let vm = OnboardingViewModel()
    vm.name = "Vlad"
    vm.monthlyIncome = 14303
    vm.expenses = [
        ExpenseEntry(name: "Food & Groceries".localized, amount: 0, icon: "cart.fill"),
        ExpenseEntry(name: "Rent / Housing".localized, amount: 0, icon: "house.fill"),
        ExpenseEntry(name: "Transportation".localized, amount: 0, icon: "car.fill"),
        ExpenseEntry(name: "Subscriptions".localized, amount: 0, icon: "repeat.circle.fill")
    ]
    return ExpensesScreen(viewModel: vm)
}
