import SwiftUI
import DesignSystem
import Utilities

/// Sheet for adding a new account during onboarding.
struct AddAccountSheet: View {
    @Binding var isPresented: Bool
    @State private var accountName = ""
    @State private var accountType: AccountType = .other

    let onAdd: (String, AccountType) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    nameField
                    typeSelector
                    quickSuggestions
                }
                .padding(Spacing.lg)
            }
            .navigationTitle("Add Account".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                cancelButton
                addButton
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Subviews

private extension AddAccountSheet {
    var nameField: some View {
        OnboardingTextField(
            "Account Name".localized,
            text: $accountName,
            prompt: "e.g., Joint Account".localized
        )
    }

    var typeSelector: some View {
        AccountTypeSelector(
            selectedType: $accountType,
            compact: false
        )
    }

    var quickSuggestions: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Quick suggestions".localized)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: Spacing.sm) {
                SuggestionChip(title: "Joint", type: .joint) { name, type in
                    accountName = name
                    accountType = type
                }
                SuggestionChip(title: "Emergency", type: .savings) { name, type in
                    accountName = name
                    accountType = type
                }
                SuggestionChip(title: "Travel", type: .savings) { name, type in
                    accountName = name
                    accountType = type
                }
            }
        }
    }
}

// MARK: - Toolbar

private extension AddAccountSheet {
    var cancelButton: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel".localized) {
                dismiss()
            }
        }
    }

    var addButton: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button {
                addAccount()
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.glassProminent)
            .tint(DiamerisColors.accentPrimary)
            .disabled(trimmedName.isEmpty)
        }
    }
}

// MARK: - Actions

private extension AddAccountSheet {
    var trimmedName: String {
        accountName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func dismiss() {
        accountName = ""
        accountType = .other
        isPresented = false
    }

    func addAccount() {
        guard !trimmedName.isEmpty else { return }
        onAdd(trimmedName, accountType)
        HapticManager.lightTap()
        dismiss()
    }
}

// MARK: - Suggestion Chip

private struct SuggestionChip: View {
    let title: String
    let type: AccountType
    let onTap: (String, AccountType) -> Void

    var body: some View {
        Button {
            onTap(title, type)
        } label: {
            Text(title)
                .font(.caption)
        }
        .buttonStyle(.glass)
    }
}

#Preview {
    AddAccountSheet(
        isPresented: .constant(true)
    ) { _, _ in }
}
