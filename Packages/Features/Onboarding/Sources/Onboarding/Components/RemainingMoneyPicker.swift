import SwiftUI
import DesignSystem
import Utilities

/// Picker for selecting where remaining money after savings should go.
struct RemainingMoneyPicker: View {
    @Binding var selectedDestination: RemainingMoneyDestination
    let hasSavingsAccount: Bool
    let hasPersonalAccount: Bool

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(availableDestinations, id: \.self) { destination in
                destinationButton(destination)
            }
        }
    }

    private var availableDestinations: [RemainingMoneyDestination] {
        var destinations: [RemainingMoneyDestination] = [.primary]

        if hasSavingsAccount {
            destinations.insert(.primarySavings, at: 0)
        }

        if hasPersonalAccount {
            destinations.append(.personal)
        }

        return destinations
    }

    private func destinationButton(_ destination: RemainingMoneyDestination) -> some View {
        Button {
            withAnimation(SpringPreset.responsive) {
                selectedDestination = destination
            }
            HapticManager.lightTap()
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: destination.icon)
                    .foregroundStyle(selectedDestination == destination ? .white : DiamerisColors.accentSecondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(destination.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(selectedDestination == destination ? .white : .primary)

                    Text(destination.description)
                        .font(.caption)
                        .foregroundStyle(selectedDestination == destination ? .white.opacity(0.8) : .secondary)
                }

                Spacer()

                if selectedDestination == destination {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                        .transition(.opacity.animation(.easeOut(duration: AnimationDuration.appear)))
                }
            }
            .padding(Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(selectedDestination == destination ? DiamerisColors.accentSecondary : Color.secondary.opacity(Opacity.faint))
                    .animation(.easeOut(duration: AnimationDuration.appear), value: selectedDestination)
            }
        }
        .buttonStyle(.plain)
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
                    hasSavingsAccount: true,
                    hasPersonalAccount: true
                )

                Divider()

                Text("Selected: \(destination.displayName)")
                    .font(.caption)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
