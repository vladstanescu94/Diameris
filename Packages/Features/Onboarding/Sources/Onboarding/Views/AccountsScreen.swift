import SwiftUI
import DesignSystem

struct AccountsScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var showingAddAccount = false
    @State private var newAccountName = ""
    @State private var newAccountPurpose = ""
    @State private var contentAppeared = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            OnboardingHeader(
                icon: "building.columns.fill",
                iconColor: DiamerisColors.accentSecondaryLight,
                title: String(localized: "Where does your income arrive?"),
                subtitle: String(localized: "Set up your accounts to track where your money goes.")
            )

            VStack(alignment: .leading, spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Primary Account", comment: "Label for primary bank account input")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    OnboardingTextField(
                        "",
                        text: $viewModel.primaryAccountName,
                        prompt: String(localized: "Main Checking")
                    )
                    .accessibilityLabel(String(localized: "Primary account name"))

                    Text("This is where your salary lands.", comment: "Helper text for primary account")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                if !viewModel.additionalAccounts.isEmpty {
                    Divider()

                    Text("Additional Accounts", comment: "Section header for additional accounts")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    GlassEffectContainer {
                        VStack(spacing: Spacing.sm) {
                            ForEach(viewModel.additionalAccounts) { account in
                                HStack {
                                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                                        Text(account.name)
                                            .font(.body)
                                        if let purpose = account.purpose, !purpose.isEmpty {
                                            Text(purpose)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Button {
                                        withAnimation(SpringPreset.responsive) {
                                            viewModel.additionalAccounts.removeAll { $0.id == account.id }
                                        }
                                        HapticManager.lightTap()
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(String(localized: "Remove \(account.name)"))
                                }
                                .padding(Spacing.sm)
                                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: CornerRadius.small))
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                }

                Button {
                    HapticManager.lightTap()
                    showingAddAccount = true
                } label: {
                    Label {
                        Text("Add Account", comment: "Button to add a new account")
                    } icon: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .font(.subheadline)
                }
                .buttonStyle(.glass)
                .accessibilityHint(String(localized: "Opens a sheet to add a new account"))
            }
            .opacity(contentAppeared ? 1 : 0)
            .offset(y: contentAppeared ? 0 : SlideOffset.standard)

            Spacer()

            OnboardingButton("Continue", isEnabled: viewModel.canAdvance) {
                viewModel.advance()
            }
            .opacity(contentAppeared ? 1 : 0)
            .offset(y: contentAppeared ? 0 : SlideOffset.standard)
            .accessibilityHint(String(localized: "Continues to complete onboarding"))
        }
        .padding(Spacing.lg)
        .sheet(isPresented: $showingAddAccount) {
            addAccountSheet
        }
        .onAppear {
            withAnimation(SpringPreset.smooth.delay(StaggerDelay.initial)) {
                contentAppeared = true
            }
        }
    }

    private var addAccountSheet: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                OnboardingTextField(
                    String(localized: "Account Name"),
                    text: $newAccountName,
                    prompt: String(localized: "e.g., Emergency Fund")
                )
                .accessibilityLabel(String(localized: "Account name"))

                OnboardingTextField(
                    String(localized: "Purpose (optional)"),
                    text: $newAccountPurpose,
                    prompt: String(localized: "e.g., 3x salary safety net")
                )
                .accessibilityLabel(String(localized: "Account purpose"))

                Text("Quick suggestions", comment: "Label for account name suggestions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: Spacing.sm) {
                    ForEach([
                        String(localized: "Emergency"),
                        String(localized: "Savings"),
                        String(localized: "Joint")
                    ], id: \.self) { suggestion in
                        Button(suggestion) {
                            newAccountName = suggestion
                        }
                        .buttonStyle(.glass)
                        .font(.caption)
                    }
                }

                Spacer()
            }
            .padding(Spacing.lg)
            .navigationTitle(String(localized: "Add Account"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) {
                        newAccountName = ""
                        newAccountPurpose = ""
                        showingAddAccount = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Add")) {
                        let trimmedName = newAccountName.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedPurpose = newAccountPurpose.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmedName.isEmpty {
                            viewModel.additionalAccounts.append(
                                AccountEntry(
                                    name: trimmedName,
                                    purpose: trimmedPurpose.isEmpty ? nil : trimmedPurpose
                                )
                            )
                        }
                        newAccountName = ""
                        newAccountPurpose = ""
                        showingAddAccount = false
                    }
                    .disabled(newAccountName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    let vm = OnboardingViewModel()
    vm.name = "Vlad"
    return AccountsScreen(viewModel: vm)
}
