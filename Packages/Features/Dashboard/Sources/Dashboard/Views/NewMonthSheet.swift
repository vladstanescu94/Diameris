import SwiftUI
import DesignSystem
import Utilities
import Domain

public struct NewMonthSheet: View {
    let currency: Currency
    let onComplete: (NewMonthCompletionData) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var flow: NewMonthFlowModel

    public init(viewModel: DashboardViewModel, onComplete: @escaping (NewMonthCompletionData) -> Void) {
        self.currency = viewModel.currency
        self.onComplete = onComplete
        self._flow = State(initialValue: NewMonthFlowModel(dashboard: viewModel))
    }

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle(stepTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        if flow.isFirstStep {
                            Button("Cancel".localized) {
                                dismiss()
                            }
                        } else {
                            Button("Back".localized, systemImage: "chevron.left", action: goBack)
                        }
                    }
                }
        }
        .presentationDetents([.large])
        .interactiveDismissDisabled(!flow.isFirstStep)
    }

    private var stepTitle: String {
        String(
            localized: "Step \(flow.step.rawValue) of \(NewMonthFlowModel.Step.allCases.count)",
            bundle: .module
        )
    }
}

// MARK: - Content

private extension NewMonthSheet {
    @ViewBuilder
    var content: some View {
        switch flow.step {
        case .salaryEntry:
            SalaryEntryStep(
                income: $flow.income,
                lastMonthIncome: flow.lastMonthIncome,
                currency: currency,
                canContinue: flow.canContinue,
                onContinue: advance
            )

        case .reconcileAccounts:
            ReconcileAccountsStep(
                flow: flow,
                currency: currency,
                onContinue: advance
            )

        case .transferPlan:
            TransferPlanStep(
                transferPlan: flow.plan,
                currency: currency,
                onComplete: completeFlow
            )
        }
    }
}

// MARK: - Actions

private extension NewMonthSheet {
    func advance() {
        withAnimation(SpringPreset.responsive) {
            flow.advance()
        }
    }

    func goBack() {
        withAnimation(SpringPreset.responsive) {
            flow.goBack()
        }
    }

    func completeFlow() {
        onComplete(flow.completionData)
        dismiss()
    }
}
