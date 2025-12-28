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
    @Namespace private var glassNamespace

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
            let accountId = account.id // Capture ID, not index, for safe deletion
            AccountRow(
                account: account,
                monthlyIncome: viewModel.monthlyIncome,
                currency: viewModel.currency.rawValue,
                hasExistingEmergency: viewModel.hasEmergencyAccount && account.accountType != .emergency,
                onTypeChange: { newType in
                    handleTypeChange(accountId: accountId, newType: newType)
                },
                onNameChange: { newName in
                    updateAccount(id: accountId) { $0.name = newName }
                },
                onMultiplierChange: { newMultiplier in
                    updateAccount(id: accountId) { $0.emergencyMultiplier = newMultiplier }
                },
                onBalanceChange: { newBalance in
                    updateAccount(id: accountId) { $0.currentBalance = newBalance }
                },
                onPrimarySavingsToggle: {
                    togglePrimarySavings(accountId: accountId)
                },
                onDelete: account.isPrimary ? nil : {
                    withAnimation(SpringPreset.responsive) {
                        deleteAccount(id: accountId)
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
    var showEmergencyPrompt: Bool { !viewModel.hasEmergencyAccount }
    var showSavingsPrompt: Bool { !viewModel.hasPrimarySavingsAccount }
    var showAnyPrompt: Bool { showEmergencyPrompt || showSavingsPrompt }

    @ViewBuilder
    var recommendedAccountsSection: some View {
        // GlassEffectContainer stays in hierarchy for morphing to work
        VStack(alignment: .leading, spacing: Spacing.md) {
            if showAnyPrompt {
                Text("Recommended".localized)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .transition(.opacity.animation(.easeOut(duration: AnimationDuration.appear)))
            }

            // Container with spacing matching the VStack spacing for proper morphing
            GlassEffectContainer(spacing: Spacing.lg) {
                VStack(spacing: Spacing.md) {
                    if showEmergencyPrompt {
                        emergencyPromptCard
                            .glassEffectID("emergencyPrompt", in: glassNamespace)
                    }

                    if showSavingsPrompt {
                        savingsPromptCard
                            .glassEffectID("savingsPrompt", in: glassNamespace)
                    }
                }
            }
        }
        .opacity(promptsAppeared ? 1 : 0)
        .offset(y: promptsAppeared ? 0 : SlideOffset.small)
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
                    withAnimation(.bouncy) {
                        addEmergencyAccount()
                    }
                } label: {
                    Text("Add".localized)
                        .font(.caption)
                }
                .buttonStyle(.glassProminent)
                .tint(DiamerisColors.accentPrimary)
                .disabled(viewModel.hasEmergencyAccount)
            }

            Text("Protects you from unexpected expenses. Recommended: 3-6 months of income.".localized)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.md)
        .glassEffect(in: .rect(cornerRadius: CornerRadius.large))
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
                    withAnimation(.bouncy) {
                        addSavingsAccount()
                    }
                } label: {
                    Text("Add".localized)
                        .font(.caption)
                }
                .buttonStyle(.glassProminent)
                .tint(DiamerisColors.accentPrimary)
                .disabled(viewModel.hasPrimarySavingsAccount)
            }

            Text("Build wealth over time. After emergency fund is full, savings go here.".localized)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.md)
        .glassEffect(in: .rect(cornerRadius: CornerRadius.large))
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
        // Guard against adding duplicate emergency accounts
        if type == .emergency && viewModel.hasEmergencyAccount {
            return
        }

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
        // Guard against rapid taps adding multiple emergency accounts
        guard !viewModel.hasEmergencyAccount else { return }
        viewModel.accounts.append(.emergency(multiplier: 3.0))
        HapticManager.lightTap()
    }

    func addSavingsAccount() {
        // Guard against rapid taps adding multiple primary savings accounts
        guard !viewModel.hasPrimarySavingsAccount else { return }
        viewModel.accounts.append(.savings(isPrimarySavings: true))
        HapticManager.lightTap()
    }

    /// Safely find and update an account by ID
    func updateAccount(id: UUID, update: (inout AccountEntry) -> Void) {
        guard let index = viewModel.accounts.firstIndex(where: { $0.id == id }) else { return }
        update(&viewModel.accounts[index])
    }

    /// Safely delete an account by ID (prevents index out of bounds)
    func deleteAccount(id: UUID) {
        viewModel.accounts.removeAll { $0.id == id }
    }

    func handleTypeChange(accountId: UUID, newType: AccountType) {
        // If changing to emergency, check if one already exists
        if newType == .emergency && viewModel.hasEmergencyAccount {
            return
        }

        updateAccount(id: accountId) { account in
            account.accountType = newType

            // If changing to emergency, set default multiplier
            if newType == .emergency {
                account.emergencyMultiplier = 3.0
            } else {
                account.emergencyMultiplier = nil
            }

            // If changing to savings and no primary savings, mark as primary
            if newType == .savings && !viewModel.hasPrimarySavingsAccount {
                account.isPrimarySavings = true
            } else if newType != .savings {
                account.isPrimarySavings = false
            }
        }
    }

    func togglePrimarySavings(accountId: UUID) {
        // Clear primary savings from other accounts
        for i in viewModel.accounts.indices {
            viewModel.accounts[i].isPrimarySavings = false
        }
        // Set this one as primary savings
        updateAccount(id: accountId) { $0.isPrimarySavings = true }
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
