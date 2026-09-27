import SwiftUI
import DesignSystem
import Utilities
import Domain

struct AddAccountSheet: View {
    @Binding var isPresented: Bool
    /// False once an emergency account exists (only one is allowed).
    let canAddEmergency: Bool
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
            .scrollIndicators(.hidden)
            .navigationTitle("Add Account".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                cancelButton
                addButton
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Subviews

private extension AddAccountSheet {
    var nameField: some View {
        OnboardingTextField(
            "Account name".localized,
            text: $accountName,
            prompt: "e.g., Joint Account".localized
        )
    }

    var typeSelector: some View {
        AccountTypeSelector(
            selectedType: $accountType,
            types: OnboardingViewModel.assignableAccountTypes,
            compact: false,
            disableEmergency: !canAddEmergency
        )
    }

    var quickSuggestions: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Quick suggestions".localized)
                .font(.caption)
                .foregroundStyle(.secondary)

            // Stack the chips vertically when they don't fit (large Dynamic Type sizes).
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Spacing.sm) { suggestionChips }
                VStack(alignment: .leading, spacing: Spacing.sm) { suggestionChips }
            }
        }
    }
}

private extension AddAccountSheet {
    var suggestionChips: some View {
        ForEach(Self.suggestions(canAddEmergency: canAddEmergency), id: \.type) { suggestion in
            SuggestionChip(title: suggestion.name, type: suggestion.type, onTap: applySuggestion)
        }
    }
}

extension AddAccountSheet {
    /// Name and type each quick-suggestion chip fills in; Emergency is offered only while none exists.
    static func suggestions(canAddEmergency: Bool) -> [(name: String, type: AccountType)] {
        var suggestions: [(name: String, type: AccountType)] = [("Joint".localized, .joint)]
        if canAddEmergency {
            suggestions.append(("Emergency".localized, .emergency))
        }
        suggestions.append(("Travel".localized, .savings))
        return suggestions
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
            Button("Add".localized, systemImage: "plus") {
                addAccount()
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.glassProminent)
            .tint(DiamerisColors.accentPrimaryFill)
            .disabled(trimmedName.isEmpty)
        }
    }
}

// MARK: - Actions

private extension AddAccountSheet {
    func applySuggestion(name: String, type: AccountType) {
        accountName = name
        accountType = type
    }

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
        isPresented: .constant(true),
        canAddEmergency: true
    ) { _, _ in }
}
