import SwiftUI
import DesignSystem
import Utilities

/// Modal flow for processing a new month's salary.
struct NewMonthSheet: View {
    @Bindable var viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep: NewMonthStep = .salaryEntry
    @State private var enteredIncome: Decimal = 0
    @State private var accountBalances: [UUID: Decimal] = [:]

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

    var body: some View {
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
                            Button {
                                goBack()
                            } label: {
                                Image(systemName: "chevron.left")
                            }
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
                transferPlan: viewModel.transferPlan,
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
    }

    func advanceToNextStep() {
        withAnimation(SpringPreset.responsive) {
            switch currentStep {
            case .salaryEntry:
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
        // TODO: Save MonthlyRecord and update account balances
        dismiss()
    }
}

// MARK: - Localization

private extension String {
    static let cancelLocalized = "Cancel".localized
}
