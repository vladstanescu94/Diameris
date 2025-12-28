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
                isPresented: $showingAddAccount
            ) { name, type in
                addAccount(name: name, type: type)
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
    func addAccount(name: String, type: AccountType) {
        let newAccount = AccountEntry(name: name, accountType: type)
        viewModel.accounts.append(newAccount)
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
    return AccountsScreen(viewModel: vm)
}
