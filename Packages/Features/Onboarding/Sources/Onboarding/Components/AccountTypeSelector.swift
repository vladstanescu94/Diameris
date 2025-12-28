import SwiftUI
import DesignSystem
import Utilities

/// Selector for choosing account type.
public struct AccountTypeSelector: View {
    @Binding var selectedType: AccountType
    let compact: Bool
    let disableEmergency: Bool

    public init(
        selectedType: Binding<AccountType>,
        compact: Bool = true,
        disableEmergency: Bool = false
    ) {
        self._selectedType = selectedType
        self.compact = compact
        self.disableEmergency = disableEmergency
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
                if type == .emergency && disableEmergency {
                    // Show disabled state for emergency when one exists
                    Button {
                        // No-op
                    } label: {
                        Label("\(type.displayName) (only one allowed)", systemImage: type.icon)
                    }
                    .disabled(true)
                } else {
                    Button {
                        HapticManager.lightTap()
                        selectedType = type
                    } label: {
                        Label(type.displayName, systemImage: type.icon)
                    }
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
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

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
        .accessibilityLabel("Account type".localized)
        .accessibilityValue(selectedType.displayName)
    }

    private var fullPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Account type".localized)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.sm) {
                ForEach(AccountType.allCases) { type in
                    let isDisabled = type == .emergency && disableEmergency

                    AccountTypeButton(
                        type: type,
                        isSelected: selectedType == type,
                        isDisabled: isDisabled
                    ) {
                        guard !isDisabled else { return }
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
    let isDisabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: type.icon)
                    .font(.title3)
                    .foregroundStyle(foregroundColor)

                Text(type.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(foregroundColor)

                Text(type.description)
                    .font(.caption2)
                    .foregroundStyle(descriptionColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.sm)
            .background {
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(backgroundColor)
            }
            .opacity(isDisabled ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityLabel(type.displayName)
        .accessibilityHint(isDisabled ? "Only one emergency account allowed".localized : type.description)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var foregroundColor: Color {
        isSelected ? .white : DiamerisColors.accentSecondary
    }

    private var descriptionColor: Color {
        isSelected ? .white.opacity(0.8) : .secondary
    }

    private var backgroundColor: Color {
        isSelected ? DiamerisColors.accentSecondary : Color.secondary.opacity(0.1)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedType: AccountType = .primary

        var body: some View {
            VStack(spacing: Spacing.xl) {
                AccountTypeSelector(selectedType: $selectedType, compact: true)

                Divider()

                AccountTypeSelector(selectedType: $selectedType, compact: false)

                Divider()

                Text("With emergency disabled:")
                    .font(.caption)

                AccountTypeSelector(selectedType: $selectedType, compact: false, disableEmergency: true)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
