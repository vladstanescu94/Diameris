import SwiftUI
import DesignSystem
import Utilities
import Domain

struct AccountsScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var showingAddAccount = false
    @State private var contentAppeared = false
    @State private var accountsAppeared = false
    @State private var promptsAppeared = false
    @Namespace private var glassNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showingAddAccount) {
            AddAccountSheet(
                isPresented: $showingAddAccount,
                canAddEmergency: viewModel.canAssign(.emergency, toAccount: nil)
            ) { name, type in
                withAnimation(reduceMotion ? nil : SpringPreset.responsive) {
                    _ = viewModel.addAccount(name: name, type: type)
                }
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
            .accessibilityAddTraits(.isHeader)
            .opacity(accountsAppeared ? 1 : 0)
    }

    var accountsList: some View {
        ForEach(viewModel.accounts.enumerated(), id: \.element.id) { index, account in
            let accountId = account.id // Captured so closures target this account even after deletions
            AccountRow(
                account: account,
                monthlyIncome: viewModel.monthlyIncome,
                currency: viewModel.currency.rawValue,
                assignableTypes: OnboardingViewModel.assignableAccountTypes,
                canAssignEmergency: viewModel.canAssign(.emergency, toAccount: accountId),
                onTypeChange: { newType in
                    withAnimation(reduceMotion ? nil : .bouncy) {
                        viewModel.changeAccountType(id: accountId, to: newType)
                    }
                },
                onNameChange: { newName in
                    viewModel.renameAccount(id: accountId, to: newName)
                },
                onMultiplierChange: { newMultiplier in
                    viewModel.updateAccount(id: accountId) { $0.emergencyMultiplier = newMultiplier }
                },
                onHardCapChange: { newHardCap in
                    viewModel.updateAccount(id: accountId) { $0.emergencyHardCap = newHardCap }
                },
                onBalanceChange: { newBalance in
                    viewModel.updateAccount(id: accountId) { $0.currentBalance = newBalance }
                },
                onPrimarySavingsToggle: {
                    viewModel.setPrimarySavings(id: accountId)
                    HapticManager.lightTap()
                },
                onDelete: account.isPrimary ? nil : {
                    withAnimation(reduceMotion ? nil : SpringPreset.responsive) {
                        viewModel.deleteAccount(id: accountId)
                    }
                    HapticManager.lightTap()
                }
            )
            .entrance(accountsAppeared, y: SlideOffset.small)
            .animation(
                reduceMotion ? nil : SpringPreset.responsive.delay(Double(index) * StaggerDelay.standard),
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
                    .accessibilityAddTraits(.isHeader)
                    .transition(.opacity.animation(.easeOut(duration: AnimationDuration.appear)))
            }

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
        .entrance(promptsAppeared, y: SlideOffset.small)
    }

    var emergencyPromptCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "shield.fill")
                    .foregroundStyle(DiamerisColors.accentSecondary)
                    .accessibilityHidden(true)

                Text("Emergency Fund".localized)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Button {
                    addEmergencyAccount()
                } label: {
                    Text("Add".localized)
                        .font(.caption)
                }
                .buttonStyle(.glassProminent)
                .tint(DiamerisColors.accentPrimaryFill)
                .disabled(viewModel.hasEmergencyAccount)
                .accessibilityLabel(String(localized: "Add \("Emergency Fund".localized)", bundle: .module))
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
                    .accessibilityHidden(true)

                Text("Savings Account".localized)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Button {
                    addSavingsAccount()
                } label: {
                    Text("Add".localized)
                        .font(.caption)
                }
                .buttonStyle(.glassProminent)
                .tint(DiamerisColors.accentPrimaryFill)
                .disabled(viewModel.hasPrimarySavingsAccount)
                .accessibilityLabel(String(localized: "Add \("Savings Account".localized)", bundle: .module))
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
                .accessibilityHidden(true)

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
    func addEmergencyAccount() {
        withAnimation(reduceMotion ? nil : .bouncy) {
            viewModel.addEmergencyAccount()
        }
        HapticManager.lightTap()
    }

    func addSavingsAccount() {
        withAnimation(reduceMotion ? nil : .bouncy) {
            viewModel.addSavingsAccount()
        }
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
