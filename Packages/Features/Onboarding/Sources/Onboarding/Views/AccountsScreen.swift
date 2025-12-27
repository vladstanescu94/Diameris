import SwiftUI
import DesignSystem
import Utilities

/// Screen for setting up accounts with smart defaults.
struct AccountsScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var showingAddAccount = false
    @State private var contentAppeared = false
    @State private var accountsAppeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                header
                accountsSection
                helperText
                continueButton
            }
            .padding(Spacing.lg)
        }
        .sheet(isPresented: $showingAddAccount) {
            AddAccountSheet(
                isPresented: $showingAddAccount,
                expenses: viewModel.expenses
            ) { name, type, linkedExpenseIds in
                addAccount(name: name, type: type, linkedExpenseIds: linkedExpenseIds)
            }
        }
        .onAppear { triggerAnimations() }
    }
}

// MARK: - Subviews

private extension AccountsScreen {
    var header: some View {
        OnboardingHeader(
            icon: "building.columns.fill",
            iconColor: DiamerisColors.accentSecondary,
            title: "Where does your money live?".localized,
            subtitle: "We've set up some common accounts. Adjust them to match your setup.".localized
        )
    }

    var accountsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionTitle
            accountsList
            addAccountButton
        }
        .opacity(contentAppeared ? 1 : 0)
    }

    var sectionTitle: some View {
        Text("Your Accounts".localized)
            .font(.headline)
            .opacity(accountsAppeared ? 1 : 0)
    }

    var accountsList: some View {
        ForEach(Array(viewModel.accounts.enumerated()), id: \.element.id) { index, account in
            AccountRow(
                account: account,
                isPrimary: account.isPrimary,
                linkedExpenses: linkedExpenses(for: account),
                onTypeChange: { newType in
                    viewModel.accounts[index].accountType = newType
                },
                onNameChange: { newName in
                    viewModel.accounts[index].name = newName
                },
                onDelete: account.isPrimary ? nil : {
                    withAnimation(SpringPreset.responsive) {
                        viewModel.accounts.remove(at: index)
                    }
                    HapticManager.lightTap()
                }
            )
            .opacity(accountsAppeared ? 1 : 0)
            .offset(y: accountsAppeared ? 0 : SlideOffset.small)
            .animation(
                SpringPreset.responsive.delay(Double(index) * StaggerDelay.standard),
                value: accountsAppeared
            )
        }
    }

    /// Returns expenses linked to the given account.
    /// For primary account: returns expenses with nil linkedAccountId (default).
    /// For other accounts: returns expenses explicitly linked to that account.
    func linkedExpenses(for account: AccountEntry) -> [ExpenseEntry] {
        let nonZeroExpenses = viewModel.expenses.filter { $0.amount > 0 }
        if account.isPrimary {
            return nonZeroExpenses.filter { $0.linkedAccountId == nil }
        } else {
            return nonZeroExpenses.filter { $0.linkedAccountId == account.id }
        }
    }

    var addAccountButton: some View {
        Button {
            HapticManager.lightTap()
            showingAddAccount = true
        } label: {
            Label {
                Text("Add Another Account".localized)
            } icon: {
                Image(systemName: "plus.circle.fill")
            }
            .font(.subheadline)
        }
        .buttonStyle(.glass)
        .opacity(accountsAppeared ? 1 : 0)
        .accessibilityHint("Opens a sheet to add a new account".localized)
    }

    var helperText: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "info.circle")
                .font(.caption)
                .foregroundStyle(DiamerisColors.accentSecondary)

            Text("Your primary account is where your salary lands".localized)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .opacity(contentAppeared ? 1 : 0)
    }

    var continueButton: some View {
        OnboardingButton("Continue".localized, isEnabled: viewModel.canAdvance) {
            viewModel.advance()
        }
        .padding(.top, Spacing.xl)
    }
}

// MARK: - Actions

private extension AccountsScreen {
    func addAccount(name: String, type: AccountType, linkedExpenseIds: Set<UUID>) {
        let newAccount = AccountEntry(name: name, accountType: type)
        viewModel.accounts.append(newAccount)

        // Link selected expenses to this account
        for expenseId in linkedExpenseIds {
            if let index = viewModel.expenses.firstIndex(where: { $0.id == expenseId }) {
                viewModel.expenses[index].linkedAccountId = newAccount.id
            }
        }
    }
}

// MARK: - Animations

private extension AccountsScreen {
    func triggerAnimations() {
        withAnimation(SpringPreset.smooth.delay(StaggerDelay.initial)) {
            contentAppeared = true
        }

        withAnimation(SpringPreset.responsive.delay(StaggerDelay.initial + AnimationDuration.fast)) {
            accountsAppeared = true
        }
    }
}

#Preview {
    let vm = OnboardingViewModel()
    vm.name = "Vlad"
    vm.accounts = AccountEntry.defaults
    vm.expenses = [
        ExpenseEntry(name: "Food & Groceries".localized, amount: 1500, icon: "cart.fill"),
        ExpenseEntry(name: "Rent / Housing".localized, amount: 3000, icon: "house.fill"),
        ExpenseEntry(name: "Transportation".localized, amount: 500, icon: "car.fill"),
        ExpenseEntry(name: "Subscriptions".localized, amount: 200, icon: "repeat.circle.fill")
    ]
    return AccountsScreen(viewModel: vm)
}
