import SwiftUI
import DesignSystem
import Utilities
import Domain

/// Modal flow for processing a new month's salary.
public struct NewMonthSheet: View {
    @Bindable var viewModel: DashboardViewModel
    let onComplete: (NewMonthCompletionData) -> Void

    public init(viewModel: DashboardViewModel, onComplete: @escaping (NewMonthCompletionData) -> Void) {
        self.viewModel = viewModel
        self.onComplete = onComplete
    }

    @Environment(\.dismiss) private var dismiss

    @State private var currentStep: NewMonthStep = .salaryEntry
    @State private var enteredIncome: Decimal = 0
    @State private var accountBalances: [UUID: Decimal] = [:]
    @State private var calculatedPlan: TransferPlan?

    enum NewMonthStep: Int, CaseIterable {
        case salaryEntry = 1
        case reconcileAccounts = 2
        case transferPlan = 3

        var title: String {
            switch self {
            case .salaryEntry: return "How much did you receive?".localized
            case .reconcileAccounts: return "Update your account balances".localized
            case .transferPlan: return "Your Transfer Plan".localized
            }
        }
    }

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle(stepTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        if currentStep == .salaryEntry {
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
        .interactiveDismissDisabled(currentStep != .salaryEntry)
        .onAppear {
            setupInitialValues()
        }
    }

    private var stepTitle: String {
        String(
            localized: "Step \(currentStep.rawValue) of \(NewMonthStep.allCases.count)",
            bundle: .module
        )
    }
}

// MARK: - Content

private extension NewMonthSheet {
    @ViewBuilder
    var content: some View {
        switch currentStep {
        case .salaryEntry:
            SalaryEntryStep(
                income: $enteredIncome,
                lastMonthIncome: viewModel.monthlyIncome,
                currency: viewModel.currency,
                onContinue: { advanceToNextStep() }
            )

        case .reconcileAccounts:
            ReconcileAccountsStep(
                accounts: viewModel.accounts,
                balances: $accountBalances,
                currency: viewModel.currency,
                onContinue: { advanceToNextStep() }
            )

        case .transferPlan:
            TransferPlanStep(
                income: enteredIncome,
                expenses: viewModel.totalExpenses,
                transferPlan: calculatedPlan ?? viewModel.transferPlan,
                currency: viewModel.currency,
                onComplete: { completeFlow() }
            )
        }
    }
}

// MARK: - Actions

private extension NewMonthSheet {
    func setupInitialValues() {
        enteredIncome = viewModel.monthlyIncome
        for account in viewModel.accounts {
            accountBalances[account.id] = account.currentBalance
        }
        // Calculate initial plan
        calculatedPlan = viewModel.calculateTransferPlan(withIncome: enteredIncome)
    }

    func advanceToNextStep() {
        withAnimation(SpringPreset.responsive) {
            switch currentStep {
            case .salaryEntry:
                // Recalculate transfer plan with new income before moving to next step
                calculatedPlan = viewModel.calculateTransferPlan(withIncome: enteredIncome)
                currentStep = .reconcileAccounts
            case .reconcileAccounts:
                currentStep = .transferPlan
            case .transferPlan:
                break
            }
        }
    }

    func goBack() {
        withAnimation(SpringPreset.responsive) {
            switch currentStep {
            case .salaryEntry:
                break
            case .reconcileAccounts:
                currentStep = .salaryEntry
            case .transferPlan:
                currentStep = .reconcileAccounts
            }
        }
    }

    func completeFlow() {
        guard let plan = calculatedPlan else {
            dismiss()
            return
        }

        // Create completion data with all necessary info
        let completionData = NewMonthCompletionData(
            income: enteredIncome,
            transferPlan: plan,
            reconciledBalances: accountBalances
        )

        // Pass data back to main app for persistence
        onComplete(completionData)
        dismiss()
    }
}

// MARK: - Localization

private extension String {
    static let cancelLocalized = "Cancel".localized
}
