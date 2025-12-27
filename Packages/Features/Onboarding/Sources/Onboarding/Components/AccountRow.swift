import SwiftUI
import DesignSystem
import Utilities

/// A row displaying an account with editable name and type.
struct AccountRow: View {
    let account: AccountEntry
    let isPrimary: Bool
    let onTypeChange: (AccountType) -> Void
    let onNameChange: (String) -> Void
    let onDelete: (() -> Void)?

    @State private var isEditing = false
    @State private var editedName: String = ""

    var body: some View {
        HStack(spacing: Spacing.md) {
            accountIcon
            accountContent
            Spacer()
            deleteButton
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
        TextField(String(localized: "Account name"), text: $editedName)
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
        Text(String(localized: "Primary"))
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
            .accessibilityLabel(String(localized: "Remove \(account.name)"))
        }
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
