import SwiftUI
import SwiftData
import DesignSystem

public struct OnboardingContainerView: View {
    @State private var viewModel = OnboardingViewModel()
    @Environment(\.modelContext) private var modelContext

    private let onComplete: () -> Void

    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            currentScreen
                .id(viewModel.currentStep)
                .transition(screenTransition)
        }
        .animation(SpringPreset.smooth, value: viewModel.currentStep)
        .safeAreaInset(edge: .top) {
            OnboardingProgressIndicator(
                currentStep: viewModel.currentStep,
                totalSteps: OnboardingViewModel.OnboardingStep.allCases.count
            )
            .padding(.top, Spacing.md)
            .padding(.horizontal, Spacing.lg)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.dismissKeyboard()
        }
        .onChange(of: viewModel.currentStep) { _, _ in
            HapticManager.selectionChanged()
        }
    }

    private var screenTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity
                .combined(with: .scale(scale: ScaleEffect.pressed))
                .combined(with: .offset(x: SlideOffset.large)),
            removal: .opacity
                .combined(with: .scale(scale: ScaleEffect.pressed))
                .combined(with: .offset(x: -SlideOffset.large))
        )
    }

    @ViewBuilder
    private var currentScreen: some View {
        switch viewModel.currentStep {
        case .name:
            NameScreen(viewModel: viewModel)
        case .income:
            IncomeScreen(viewModel: viewModel)
        case .expenses:
            ExpensesScreen(viewModel: viewModel)
        case .accounts:
            AccountsScreen(viewModel: viewModel)
        case .complete:
            CompleteScreen(viewModel: viewModel) {
                viewModel.save(context: modelContext)
                onComplete()
            }
        }
    }
}

#Preview {
    OnboardingContainerView(onComplete: {})
        .modelContainer(for: [UserProfile.self, Income.self, Expense.self, Account.self], inMemory: true)
}
