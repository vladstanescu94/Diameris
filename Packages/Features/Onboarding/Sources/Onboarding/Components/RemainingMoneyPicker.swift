import SwiftUI
import DesignSystem
import Utilities
import Domain

struct RemainingMoneyPicker: View {
    @Binding var selectedDestination: RemainingMoneyDestination
    /// Only destinations backed by an existing account.
    let destinations: [RemainingMoneyDestination]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(destinations) { destination in
                destinationButton(destination)
            }
        }
    }

    private func destinationButton(_ destination: RemainingMoneyDestination) -> some View {
        let isSelected = selectedDestination == destination

        return Button {
            withAnimation(reduceMotion ? nil : SpringPreset.responsive) {
                selectedDestination = destination
            }
            HapticManager.lightTap()
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: destination.icon)
                    .foregroundStyle(DiamerisColors.accentSecondary)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(destination.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Text(destination.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(DiamerisColors.accentSecondary)
                        .transition(.opacity.animation(.easeOut(duration: AnimationDuration.appear)))
                        .accessibilityHidden(true)
                }
            }
            .padding(Spacing.md)
            .background {
                // Tinted fill + border instead of white-on-cyan text (fails 4.5:1 in light mode).
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(isSelected ? DiamerisColors.accentSecondary.opacity(Opacity.light) : Color.secondary.opacity(Opacity.faint))
                    .stroke(isSelected ? DiamerisColors.accentSecondary : .clear)
                    .animation(.easeOut(duration: AnimationDuration.appear), value: selectedDestination)
            }
            .contentShape(.rect(cornerRadius: CornerRadius.medium))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - RemainingMoneyDestination Icon

extension RemainingMoneyDestination {
    var icon: String {
        switch self {
        case .primarySavings: return "banknote.fill"
        case .personal: return "person.fill"
        case .primary: return "building.columns.fill"
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var destination: RemainingMoneyDestination = .primarySavings

        var body: some View {
            VStack(spacing: Spacing.lg) {
                RemainingMoneyPicker(
                    selectedDestination: $destination,
                    destinations: RemainingMoneyDestination.allCases
                )

                Divider()

                Text(verbatim: "Selected: \(destination.displayName)")
                    .font(.caption)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
