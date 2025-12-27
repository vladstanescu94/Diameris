import SwiftUI
import SwiftData
import DesignSystem
import Utilities

public struct OnboardingContainerView: View {
    @State private var viewModel = OnboardingViewModel()
    @Environment(\.modelContext) private var modelContext

    private let onComplete: () -> Void

    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    public var body: some View {
        NavigationStack {
            screenContainer
                .toolbar { progressToolbarItem }
                .toolbarVisibility(toolbarVisibility, for: .navigationBar)
        }
        .contentShape(Rectangle())
        .onTapGesture { viewModel.dismissKeyboard() }
        .onChange(of: viewModel.currentStep) { _, _ in
            HapticManager.selectionChanged()
        }
    }
}

// MARK: - Subviews

private extension OnboardingContainerView {
    var screenContainer: some View {
        ZStack {
            currentScreen
                .id(viewModel.currentStep)
                .transition(screenTransition)
        }
        .animation(SpringPreset.smooth, value: viewModel.currentStep)
    }

    @ViewBuilder
    var currentScreen: some View {
        switch viewModel.currentStep {
        case .welcome:
            WelcomeScreen(viewModel: viewModel)
        case .name:
            NameScreen(viewModel: viewModel)
        case .income:
            IncomeScreen(viewModel: viewModel)
        case .savingsGoals:
            SavingsGoalsScreen(viewModel: viewModel)
        case .expenses:
            ExpensesScreen(viewModel: viewModel)
        case .accounts:
            AccountsScreen(viewModel: viewModel)
        case .transferPlan:
            TransferPlanScreen(viewModel: viewModel) {
                viewModel.save(context: modelContext)
                onComplete()
            }
        }
    }
}

// MARK: - Toolbar

private extension OnboardingContainerView {
    @ToolbarContentBuilder
    var progressToolbarItem: some ToolbarContent {
        if showsProgressIndicator {
            ToolbarItem(placement: .principal) {
                OnboardingProgressIndicator(
                    currentStep: viewModel.currentStep,
                    totalSteps: OnboardingViewModel.OnboardingStep.allCases.count - 2
                )
            }
        }
    }

    var showsProgressIndicator: Bool {
        viewModel.currentStep != .welcome && viewModel.currentStep != .transferPlan
    }

    var toolbarVisibility: Visibility {
        showsProgressIndicator ? .visible : .hidden
    }
}

// MARK: - Transitions

private extension OnboardingContainerView {
    var screenTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity
                .combined(with: .scale(scale: ScaleEffect.pressed))
                .combined(with: .offset(x: SlideOffset.large)),
            removal: .opacity
                .combined(with: .scale(scale: ScaleEffect.pressed))
                .combined(with: .offset(x: -SlideOffset.large))
        )
    }
}

#Preview {
    OnboardingContainerView(onComplete: {})
        .modelContainer(for: [
            UserProfile.self,
            Income.self,
            Expense.self,
            Account.self,
            SavingsGoal.self,
            SavingsAllocation.self
        ], inMemory: true)
}
