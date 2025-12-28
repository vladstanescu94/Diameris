import SwiftUI
import DesignSystem
import Utilities

/// Screen for setting up accounts with guided prompts for emergency and savings.
struct AccountsScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var showingAddAccount = false
    @State private var contentAppeared = false
    @State private var accountsAppeared = false
    @State private var promptsAppeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                header
                accountsSection
                recommendedAccountsSection
                helperText
                continueButton
            }
            .padding(Spacing.lg)
        }
        .sheet(isPresented: $showingAddAccount) {
            AddAccountSheet(
                isPresented: $showingAddAccount
            ) { name, type in
                addAccount(name: name, type: type)
            }
        }
        .onAppear { triggerAnimations() }
    }
}

// MARK: - Header

private extension AccountsScreen {
    var header: some View {
        OnboardingHeader(
            icon: "building.columns.fill",
            iconColor: DiamerisColors.accentSecondary,
            title: "Where does your money live?".localized,
            subtitle: "Set up your accounts. We recommend an emergency fund and savings account.".localized
        )
    }
}

// MARK: - Accounts Section

private extension AccountsScreen {
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
                monthlyIncome: viewModel.monthlyIncome,
                currency: viewModel.currency.rawValue,
                hasExistingEmergency: viewModel.hasEmergencyAccount && account.accountType != .emergency,
                onTypeChange: { newType in
                    handleTypeChange(index: index, newType: newType)
                },
                onNameChange: { newName in
                    viewModel.accounts[index].name = newName
                },
                onMultiplierChange: { newMultiplier in
                    viewModel.accounts[index].emergencyMultiplier = newMultiplier
                },
                onBalanceChange: { newBalance in
                    viewModel.accounts[index].currentBalance = newBalance
                },
                onPrimarySavingsToggle: {
                    togglePrimarySavings(index: index)
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
}

// MARK: - Recommended Accounts Section

private extension AccountsScreen {
    @ViewBuilder
    var recommendedAccountsSection: some View {
        let showEmergencyPrompt = !viewModel.hasEmergencyAccount
        let showSavingsPrompt = !viewModel.hasPrimarySavingsAccount

        if showEmergencyPrompt || showSavingsPrompt {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Recommended".localized)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                if showEmergencyPrompt {
                    emergencyPromptCard
                }

                if showSavingsPrompt {
                    savingsPromptCard
                }
            }
            .opacity(promptsAppeared ? 1 : 0)
            .offset(y: promptsAppeared ? 0 : SlideOffset.small)
        }
    }

    var emergencyPromptCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "shield.fill")
                    .foregroundStyle(DiamerisColors.accentSecondary)

                Text("Emergency Fund".localized)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Button {
                    addEmergencyAccount()
                    HapticManager.lightTap()
                } label: {
                    Text("Add".localized)
                        .font(.caption)
                }
                .buttonStyle(.glassProminent)
                .tint(DiamerisColors.accentPrimary)
            }

            Text("Protects you from unexpected expenses. Recommended: 3-6 months of income.".localized)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.md)
        .glassCard()
    }

    var savingsPromptCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "banknote.fill")
                    .foregroundStyle(DiamerisColors.accentSecondary)

                Text("Savings Account".localized)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Button {
                    addSavingsAccount()
                    HapticManager.lightTap()
                } label: {
                    Text("Add".localized)
                        .font(.caption)
                }
                .buttonStyle(.glassProminent)
                .tint(DiamerisColors.accentPrimary)
            }

            Text("Build wealth over time. After emergency fund is full, savings go here.".localized)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.md)
        .glassCard()
    }
}

// MARK: - Helper Text & Continue Button

private extension AccountsScreen {
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
    func addAccount(name: String, type: AccountType) {
        var newAccount = AccountEntry(name: name, accountType: type)

        // If adding emergency, set default multiplier
        if type == .emergency {
            newAccount.emergencyMultiplier = 3.0
        }

        // If adding savings and no primary savings exists, mark as primary
        if type == .savings && !viewModel.hasPrimarySavingsAccount {
            newAccount.isPrimarySavings = true
        }

        viewModel.accounts.append(newAccount)
    }

    func addEmergencyAccount() {
        viewModel.accounts.append(.emergency(multiplier: 3.0))
    }

    func addSavingsAccount() {
        viewModel.accounts.append(.savings(isPrimarySavings: true))
    }

    func handleTypeChange(index: Int, newType: AccountType) {
        // If changing to emergency, check if one already exists
        if newType == .emergency && viewModel.hasEmergencyAccount {
            // Don't allow multiple emergency accounts
            return
        }

        viewModel.accounts[index].accountType = newType

        // If changing to emergency, set default multiplier
        if newType == .emergency {
            viewModel.accounts[index].emergencyMultiplier = 3.0
        } else {
            viewModel.accounts[index].emergencyMultiplier = nil
        }

        // If changing to savings and no primary savings, mark as primary
        if newType == .savings && !viewModel.hasPrimarySavingsAccount {
            viewModel.accounts[index].isPrimarySavings = true
        } else if newType != .savings {
            viewModel.accounts[index].isPrimarySavings = false
        }
    }

    func togglePrimarySavings(index: Int) {
        // Clear primary savings from other accounts
        for i in viewModel.accounts.indices {
            viewModel.accounts[i].isPrimarySavings = false
        }
        // Set this one as primary savings
        viewModel.accounts[index].isPrimarySavings = true
        HapticManager.lightTap()
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

        withAnimation(SpringPreset.responsive.delay(StaggerDelay.initial + AnimationDuration.standard)) {
            promptsAppeared = true
        }
    }
}

#Preview {
    let vm = OnboardingViewModel()
    vm.name = "Vlad"
    vm.monthlyIncome = 14303
    vm.accounts = [.primary()]
    return AccountsScreen(viewModel: vm)
}
