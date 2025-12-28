import SwiftUI
import DesignSystem
import Utilities
import Domain

/// Screen for entering main expenses with impact display.
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
        .onAppear { triggerAnimations() }
    }
}

// MARK: - Computed Properties

private extension ExpensesScreen {
    var totalExpenses: Decimal {
        viewModel.expenses.reduce(0) { $0 + $1.amount }
    }

    var availableForGoals: Decimal {
        max(0, viewModel.monthlyIncome - totalExpenses)
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
                ForEach(Array(viewModel.expenses.enumerated()), id: \.element.id) { index, expense in
                    ExpenseRow(
                        icon: expense.icon,
                        name: expense.name,
                        amount: $viewModel.expenses[index].amount,
                        currency: viewModel.currency,
                        linkedAccountId: $viewModel.expenses[index].linkedAccountId,
                        accounts: viewModel.accounts
                    )
                    .opacity(index < rowsAppeared.count && rowsAppeared[index] ? 1 : 0)
                    .offset(x: index < rowsAppeared.count && rowsAppeared[index] ? 0 : SlideOffset.large)
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
            .background(availableForGoals > 0 ? DiamerisColors.accentSecondary.opacity(0.1) : Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            .opacity(impactAppeared ? 1 : 0)
            .scaleEffect(impactAppeared ? 1 : 0.95)
            .animation(.smooth, value: availableForGoals)
        }
    }

    var impactHeader: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: availableForGoals > 0 ? "arrow.right.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(availableForGoals > 0 ? DiamerisColors.accentSecondary : .orange)

            Text("After expenses".localized)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    var impactAmount: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
            Text(AmountFormatter.formatForDisplay(availableForGoals, currency: viewModel.currency.rawValue))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(availableForGoals > 0 ? DiamerisColors.accentSecondary : .orange)
                .contentTransition(.numericText())

            Text("available for your goals".localized)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    var helperText: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "info.circle")
                .font(.caption)
                .foregroundStyle(.secondary)

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
            .accessibilityHint("Continues to the accounts step".localized)

            OnboardingSecondaryButton("Skip for now".localized) {
                for index in viewModel.expenses.indices {
                    viewModel.expenses[index].amount = 0
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
