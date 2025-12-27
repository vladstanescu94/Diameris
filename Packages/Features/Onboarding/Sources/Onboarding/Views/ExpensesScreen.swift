import SwiftUI
import DesignSystem
import Utilities

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
            title: String(localized: "Almost there!"),
            subtitle: String(localized: "A quick look at your main expenses. Don't worry about being exact — estimates are fine.")
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
                        currency: viewModel.currency
                    )
                    .opacity(index < rowsAppeared.count && rowsAppeared[index] ? 1 : 0)
                    .offset(x: index < rowsAppeared.count && rowsAppeared[index] ? 0 : SlideOffset.large)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "Expense categories"))
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

            Text(String(localized: "After expenses"))
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

            Text(String(localized: "available for your goals"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    var helperText: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "info.circle")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(String(localized: "These stay in your main account for automatic payments"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .opacity(contentAppeared ? 1 : 0)
    }

    var actionButtons: some View {
        VStack(spacing: Spacing.sm) {
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
            .accessibilityHint(String(localized: "Skips expense entry and continues"))
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
        ExpenseEntry(name: String(localized: "Food & Groceries"), amount: 0, icon: "cart.fill"),
        ExpenseEntry(name: String(localized: "Rent / Housing"), amount: 0, icon: "house.fill"),
        ExpenseEntry(name: String(localized: "Transportation"), amount: 0, icon: "car.fill"),
        ExpenseEntry(name: String(localized: "Subscriptions"), amount: 0, icon: "repeat.circle.fill")
    ]
    return ExpensesScreen(viewModel: vm)
}
