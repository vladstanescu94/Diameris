import SwiftUI
import DesignSystem
import Utilities

/// A row displaying an account with editable name and type.
struct AccountRow: View {
    let account: AccountEntry
    let isPrimary: Bool
    let linkedExpenses: [ExpenseEntry]
    let onTypeChange: (AccountType) -> Void
    let onNameChange: (String) -> Void
    let onDelete: (() -> Void)?

    @State private var isEditing = false
    @State private var editedName: String = ""

    init(
        account: AccountEntry,
        isPrimary: Bool,
        linkedExpenses: [ExpenseEntry] = [],
        onTypeChange: @escaping (AccountType) -> Void,
        onNameChange: @escaping (String) -> Void,
        onDelete: (() -> Void)?
    ) {
        self.account = account
        self.isPrimary = isPrimary
        self.linkedExpenses = linkedExpenses
        self.onTypeChange = onTypeChange
        self.onNameChange = onNameChange
        self.onDelete = onDelete
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.md) {
                accountIcon
                accountContent
                Spacer()
                deleteButton
            }

            if !linkedExpenses.isEmpty {
                linkedExpensesChips
            }
        }
        .padding(Spacing.md)
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(account.name), \(account.accountType.displayName)\(isPrimary ? ", primary account" : "")")
    }
}

// MARK: - Subviews

private extension AccountRow {
    var accountIcon: some View {
        ZStack {
            Circle()
                .fill(account.accountType.color.opacity(0.15))
                .frame(width: 44, height: 44)

            Image(systemName: account.accountType.icon)
                .font(.title3)
                .foregroundStyle(account.accountType.color)
        }
        .accessibilityHidden(true)
    }

    var accountContent: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            if isEditing {
                nameTextField
            } else {
                nameDisplay
            }

            AccountTypeSelector(
                selectedType: .init(
                    get: { account.accountType },
                    set: { onTypeChange($0) }
                ),
                compact: true
            )
        }
    }

    var nameTextField: some View {
        TextField("Account name".localized, text: $editedName)
            .font(.headline)
            .textFieldStyle(.plain)
            .onSubmit {
                onNameChange(editedName)
                isEditing = false
            }
    }

    var nameDisplay: some View {
        HStack(spacing: Spacing.xs) {
            Text(account.name)
                .font(.headline)

            if isPrimary {
                primaryBadge
            }
        }
        .onTapGesture {
            editedName = account.name
            isEditing = true
        }
    }

    var primaryBadge: some View {
        Text("Primary".localized)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(DiamerisColors.accentPrimary)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, 2)
            .background(DiamerisColors.accentPrimary.opacity(0.15))
            .clipShape(Capsule())
    }

    @ViewBuilder
    var deleteButton: some View {
        if let onDelete = onDelete {
            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "Remove \(account.name)", bundle: .module))
        }
    }

    var linkedExpensesChips: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "creditcard.fill")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            ForEach(linkedExpenses.prefix(3)) { expense in
                Text(expense.name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
            }

            if linkedExpenses.count > 3 {
                Text("+\(linkedExpenses.count - 3)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.leading, 44 + Spacing.md)
    }
}

// MARK: - AccountType Color Extension

extension AccountType {
    var color: Color {
        switch self {
        case .checking: DiamerisColors.accentPrimary
        case .savings: DiamerisColors.accentSecondary
        case .personal: .orange
        case .joint: .purple
        case .other: .secondary
        }
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        AccountRow(
            account: AccountEntry(name: "Main Account", accountType: .checking, isPrimary: true),
            isPrimary: true,
            linkedExpenses: [
                ExpenseEntry(name: "Food", amount: 500, icon: "cart.fill"),
                ExpenseEntry(name: "Rent", amount: 1000, icon: "house.fill")
            ],
            onTypeChange: { _ in },
            onNameChange: { _ in },
            onDelete: nil
        )

        AccountRow(
            account: AccountEntry(name: "Savings", accountType: .savings),
            isPrimary: false,
            onTypeChange: { _ in },
            onNameChange: { _ in },
            onDelete: { }
        )
    }
    .padding()
}
