import SwiftUI
import DesignSystem

struct AccountsScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var showingAddAccount = false
    @State private var newAccountName = ""
    @State private var newAccountPurpose = ""

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            VStack(spacing: Spacing.md) {
                Image(systemName: "building.columns.fill")
                    .iconXxl()
                    .foregroundStyle(DiamerisColors.accentSecondaryLight)

                Text("Where does your income arrive?")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Set up your accounts to track where your money goes.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Primary Account")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    OnboardingTextField(
                        "",
                        text: $viewModel.primaryAccountName,
                        prompt: String(localized: "Main Checking")
                    )

                    Text("This is where your salary lands.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                if !viewModel.additionalAccounts.isEmpty {
                    Divider()

                    Text("Additional Accounts")
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
                                        viewModel.additionalAccounts.removeAll { $0.id == account.id }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(Spacing.sm)
                                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: CornerRadius.small))
                            }
                        }
                    }
                }

                Button {
                    showingAddAccount = true
                } label: {
                    Label("Add Account", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                }
                .buttonStyle(.glass)
            }

            Spacer()

            Button {
                viewModel.advance()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: ComponentSize.buttonHeight)
            }
            .buttonStyle(.glassProminent)
            .disabled(!viewModel.canAdvance)
        }
        .padding(Spacing.lg)
        .sheet(isPresented: $showingAddAccount) {
            addAccountSheet
        }
    }

    private var addAccountSheet: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                OnboardingTextField(
                    "Account Name",
                    text: $newAccountName,
                    prompt: String(localized: "e.g., Emergency Fund")
                )

                OnboardingTextField(
                    "Purpose (optional)",
                    text: $newAccountPurpose,
                    prompt: String(localized: "e.g., 3x salary safety net")
                )

                Text("Quick suggestions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: Spacing.sm) {
                    ForEach(["Emergency", "Savings", "Joint"], id: \.self) { suggestion in
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
            .navigationTitle("Add Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        newAccountName = ""
                        newAccountPurpose = ""
                        showingAddAccount = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
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
