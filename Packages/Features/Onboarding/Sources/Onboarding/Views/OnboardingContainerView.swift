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
                .transition(.push(from: .trailing))
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.currentStep)
        .safeAreaInset(edge: .top) {
            progressIndicator
        }
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

    private var progressIndicator: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(OnboardingViewModel.OnboardingStep.allCases, id: \.self) { step in
                Circle()
                    .fill(step.rawValue <= viewModel.currentStep.rawValue
                        ? DiamerisColors.accentPrimaryLight
                        : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.top, Spacing.md)
        .animation(.easeInOut, value: viewModel.currentStep)
    }
}

#Preview {
    OnboardingContainerView(onComplete: {})
        .modelContainer(for: [UserProfile.self, Income.self, Expense.self, Account.self], inMemory: true)
}
