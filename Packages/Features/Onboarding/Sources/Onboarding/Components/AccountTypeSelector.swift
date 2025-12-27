import SwiftUI
import DesignSystem
import Utilities

/// Selector for choosing account type.
public struct AccountTypeSelector: View {
    @Binding var selectedType: AccountType
    let compact: Bool

    public init(
        selectedType: Binding<AccountType>,
        compact: Bool = true
    ) {
        self._selectedType = selectedType
        self.compact = compact
    }

    public var body: some View {
        if compact {
            compactPicker
        } else {
            fullPicker
        }
    }

    private var compactPicker: some View {
        Menu {
            ForEach(AccountType.allCases) { type in
                Button {
                    HapticManager.lightTap()
                    selectedType = type
                } label: {
                    Label(type.displayName, systemImage: type.icon)
                }
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: selectedType.icon)
                    .font(.caption)
                    .foregroundStyle(DiamerisColors.accentSecondary)

                Text(selectedType.displayName)
                    .font(.caption)
                    .foregroundStyle(.primary)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background {
                Capsule()
                    .fill(Color.secondary.opacity(0.1))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "Account type"))
        .accessibilityValue(selectedType.displayName)
    }

    private var fullPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(String(localized: "Account type"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.sm) {
                ForEach(AccountType.allCases) { type in
                    AccountTypeButton(
                        type: type,
                        isSelected: selectedType == type
                    ) {
                        HapticManager.lightTap()
                        selectedType = type
                    }
                }
            }
        }
    }
}

/// Button for a single account type option.
private struct AccountTypeButton: View {
    let type: AccountType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: type.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : DiamerisColors.accentSecondary)

                Text(type.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? .white : .primary)

                Text(type.description)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.sm)
            .background {
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(isSelected ? DiamerisColors.accentSecondary : Color.secondary.opacity(0.1))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(type.displayName)
        .accessibilityHint(type.description)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedType: AccountType = .checking

        var body: some View {
            VStack(spacing: Spacing.xl) {
                AccountTypeSelector(selectedType: $selectedType, compact: true)

                Divider()

                AccountTypeSelector(selectedType: $selectedType, compact: false)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
