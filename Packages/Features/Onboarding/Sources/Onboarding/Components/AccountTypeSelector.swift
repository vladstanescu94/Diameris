import SwiftUI
import DesignSystem
import Utilities
import Domain

public struct AccountTypeSelector: View {
    @Binding var selectedType: AccountType
    let types: [AccountType]
    let compact: Bool
    let disableEmergency: Bool

    public init(
        selectedType: Binding<AccountType>,
        types: [AccountType] = AccountType.allCases,
        compact: Bool = true,
        disableEmergency: Bool = false
    ) {
        self._selectedType = selectedType
        self.types = types
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
            ForEach(types) { type in
                if type == .emergency && disableEmergency {
                    Button {} label: {
                        Label(
                            String(localized: "\(type.displayName) (only one allowed)", bundle: .module),
                            systemImage: type.icon
                        )
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

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background {
                Capsule()
                    .fill(Color.secondary.opacity(Opacity.faint))
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
                ForEach(types) { type in
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
                    .stroke(isSelected ? DiamerisColors.accentSecondary : .clear)
            }
            .opacity(isDisabled ? Opacity.half : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityLabel(type.displayName)
        .accessibilityHint(isDisabled ? "Only one emergency account allowed".localized : type.description)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // Selection is shown by a tinted fill + border rather than white-on-cyan text,
    // which falls below 4.5:1 contrast in light mode.
    private var foregroundColor: Color {
        .primary
    }

    private var descriptionColor: Color {
        .secondary
    }

    private var backgroundColor: Color {
        isSelected ? DiamerisColors.accentSecondary.opacity(Opacity.light) : Color.secondary.opacity(Opacity.faint)
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
