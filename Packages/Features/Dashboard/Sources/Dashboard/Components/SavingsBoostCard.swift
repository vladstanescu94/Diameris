import SwiftUI
import DesignSystem
import Domain

/// Keeps an active boost visible on Home so it isn't left on by accident.
struct SavingsBoostCard: View {
    let allocation: SavingsAllocationEntry
    let onTurnOff: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var layout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.sm))
            : AnyLayout(HStackLayout(spacing: Spacing.md))
    }

    var body: some View {
        layout {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Label {
                    Text("Savings Boost is on", bundle: .module)
                        .font(.headline)
                } icon: {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.yellow)
                }

                Text(SavingsBoostText.detail(for: allocation))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            Button(action: onTurnOff) {
                Text("Turn Off", bundle: .module, comment: "Switches off Savings Boost")
            }
            .buttonStyle(.glass)
        }
        .glassCard()
    }
}

/// Boost toggle for the New Month plan; the plan above it updates as it flips.
struct SavingsBoostToggle: View {
    @Binding var isOn: Bool
    let allocation: SavingsAllocationEntry

    var body: some View {
        Toggle(isOn: $isOn) {
            Label {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Savings Boost", bundle: .module)
                        .font(.subheadline)
                        .bold()

                    Text(SavingsBoostText.detail(for: allocation))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(isOn ? .yellow : .secondary)
            }
        }
        .tint(DiamerisColors.accentPrimary)
        .glassCard()
    }
}

private enum SavingsBoostText {
    static func detail(for allocation: SavingsAllocationEntry) -> String {
        let base = allocation.percentageDisplay
        guard allocation.isBoostActive else {
            return String(localized: "Saving \(base) of available income", bundle: .module)
        }
        let boosted = allocation.effectivePercentageDisplay
        return String(localized: "Saving \(boosted) of available income instead of \(base)", bundle: .module)
    }
}

#Preview {
    @Previewable @State var isOn = true
    let allocation = SavingsAllocationEntry(percentage: 0.25, boostEnabled: true, boostMultiplier: 3)

    VStack(spacing: Spacing.md) {
        SavingsBoostCard(allocation: allocation, onTurnOff: {})

        SavingsBoostToggle(isOn: $isOn, allocation: {
            var copy = allocation
            copy.boostEnabled = isOn
            return copy
        }())
    }
    .padding()
}
