import SwiftUI
import DesignSystem
import Utilities

public struct DashboardView: View {
    @Bindable var viewModel: DashboardViewModel
    var onSettingsTapped: (() -> Void)?
    var onDevToolsTapped: (() -> Void)?

    public init(
        viewModel: DashboardViewModel,
        onSettingsTapped: (() -> Void)? = nil,
        onDevToolsTapped: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.onSettingsTapped = onSettingsTapped
        self.onDevToolsTapped = onDevToolsTapped
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                dashboardBody
            }
            .scrollIndicators(.hidden)
            .navigationTitle(viewModel.currentMonthDisplay)
            .toolbar {
                toolbarButtons
            }
        }
    }
}

// MARK: - Toolbar

private extension DashboardView {
    @ToolbarContentBuilder
    var toolbarButtons: some ToolbarContent {
        // One system item per button (not an HStack in a single item) so each keeps its own hit target.
        ToolbarItemGroup(placement: .topBarTrailing) {
            if let onSettingsTapped {
                Button("Settings".localized, systemImage: "gearshape", action: onSettingsTapped)
            }

            #if DEBUG
            if let onDevToolsTapped {
                Button("Developer Tools".localized, systemImage: "hammer.fill", action: onDevToolsTapped)
            }
            #endif
        }
    }
}

// MARK: - Content

private extension DashboardView {
    @ViewBuilder
    var dashboardBody: some View {
        if viewModel.hasCompletedOnboarding {
            dashboardContent
        } else {
            emptyState
        }
    }

    @ViewBuilder
    var dashboardContent: some View {
        // Computed once per body: every total below comes from Domain's TransferCalculator.
        let plan = viewModel.transferPlan

        VStack(spacing: Spacing.md) {
            SummaryCard(
                income: plan.income,
                expenses: plan.totalExpenses,
                savings: plan.totalSavings,
                remainingMoney: plan.remainingMoney,
                remainingDestination: plan.remainingDestination,
                shortfall: plan.shortfall,
                currency: viewModel.currency
            )

            if let emergencyAccount = viewModel.emergencyAccount,
               let progress = viewModel.emergencyProgress,
               let target = viewModel.emergencyTarget {
                EmergencyProgressCard(
                    currentBalance: emergencyAccount.currentBalance,
                    target: target,
                    progress: progress,
                    multiplier: emergencyAccount.emergencyMultiplier ?? 3.0,
                    emergencyHardCap: emergencyAccount.emergencyHardCap,
                    currency: viewModel.currency
                )
            }

            AccountBalancesSection(
                accounts: viewModel.accounts,
                currency: viewModel.currency
            )

            ExpenseBreakdownCard(
                expenses: viewModel.expenses,
                totalExpenses: plan.totalExpenses,
                currency: viewModel.currency
            )
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    var emptyState: some View {
        ContentUnavailableView {
            Label("No data yet".localized, systemImage: "chart.bar.doc.horizontal")
        } description: {
            Text("Complete onboarding to start tracking your finances".localized)
        }
    }
}

#Preview {
    let viewModel = DashboardViewModel()
    viewModel.userName = "Vlad"
    viewModel.monthlyIncome = 14303
    viewModel.currency = .ron
    viewModel.hasCompletedOnboarding = true
    viewModel.accounts = [
        DashboardAccount(
            id: UUID(),
            name: "BT",
            accountType: .primary,
            isPrimary: true,
            isPrimarySavings: false,
            emergencyMultiplier: nil,
            currentBalance: 5000
        ),
        DashboardAccount(
            id: UUID(),
            name: "Emergency",
            accountType: .emergency,
            isPrimary: false,
            isPrimarySavings: false,
            emergencyMultiplier: 3.0,
            emergencyHardCap: 40000,
            currentBalance: 37056
        ),
        DashboardAccount(
            id: UUID(),
            name: "Savings",
            accountType: .savings,
            isPrimary: false,
            isPrimarySavings: true,
            emergencyMultiplier: nil,
            currentBalance: 5200
        ),
        DashboardAccount(
            id: UUID(),
            name: "Personal",
            accountType: .personal,
            isPrimary: false,
            isPrimarySavings: false,
            emergencyMultiplier: nil,
            currentBalance: 1500
        )
    ]
    viewModel.expenses = [
        DashboardExpense(id: UUID(), name: "Auto", amount: 3600, icon: "car.fill", linkedAccountId: nil),
        DashboardExpense(id: UUID(), name: "Food", amount: 3000, icon: "cart.fill", linkedAccountId: nil),
        DashboardExpense(id: UUID(), name: "Subscriptions", amount: 605, icon: "creditcard.fill", linkedAccountId: nil)
    ]

    return ScrollView {
        DashboardView(viewModel: viewModel)
    }
}
