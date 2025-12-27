import SwiftUI
import DesignSystem
import Utilities

/// Sheet for adding a new account during onboarding.
struct AddAccountSheet: View {
    @Binding var isPresented: Bool
    @State private var accountName = ""
    @State private var accountType: AccountType = .other
    @State private var selectedExpenseIds: Set<UUID> = []

    let expenses: [ExpenseEntry]
    let onAdd: (String, AccountType, Set<UUID>) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    nameField
                    typeSelector
                    quickSuggestions
                    if hasLinkableExpenses {
                        expenseLinkingSection
                    }
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
        .presentationDetents([.medium, .large])
    }

    /// Expenses that aren't already linked to another account
    private var linkableExpenses: [ExpenseEntry] {
        expenses.filter { $0.linkedAccountId == nil }
    }

    private var hasLinkableExpenses: Bool {
        !linkableExpenses.isEmpty
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

    var expenseLinkingSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Link expenses (optional)".localized)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("These expenses will be paid from this account".localized)
                .font(.caption2)
                .foregroundStyle(.tertiary)

            VStack(spacing: Spacing.xs) {
                ForEach(linkableExpenses) { expense in
                    ExpenseLinkRow(
                        expense: expense,
                        isSelected: selectedExpenseIds.contains(expense.id),
                        onToggle: {
                            if selectedExpenseIds.contains(expense.id) {
                                selectedExpenseIds.remove(expense.id)
                            } else {
                                selectedExpenseIds.insert(expense.id)
                            }
                        }
                    )
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
        selectedExpenseIds = []
        isPresented = false
    }

    func addAccount() {
        guard !trimmedName.isEmpty else { return }
        onAdd(trimmedName, accountType, selectedExpenseIds)
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

// MARK: - Expense Link Row

private struct ExpenseLinkRow: View {
    let expense: ExpenseEntry
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: expense.icon)
                    .font(.subheadline)
                    .foregroundStyle(isSelected ? DiamerisColors.accentPrimary : .secondary)
                    .frame(width: ComponentSize.iconContainer)

                Text(expense.name)
                    .font(.subheadline)
                    .foregroundStyle(isSelected ? .primary : .secondary)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? DiamerisColors.accentPrimary : Color.secondary.opacity(Opacity.subtle))
            }
            .padding(.vertical, Spacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AddAccountSheet(
        isPresented: .constant(true),
        expenses: [
            ExpenseEntry(name: "Food & Groceries", amount: 0, icon: "cart.fill"),
            ExpenseEntry(name: "Rent / Housing", amount: 0, icon: "house.fill"),
            ExpenseEntry(name: "Transportation", amount: 0, icon: "car.fill"),
            ExpenseEntry(name: "Subscriptions", amount: 0, icon: "repeat.circle.fill")
        ]
    ) { _, _, _ in }
}
