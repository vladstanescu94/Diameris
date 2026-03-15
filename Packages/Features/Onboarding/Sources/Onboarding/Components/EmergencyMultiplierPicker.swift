import SwiftUI
import DesignSystem
import Utilities

/// Picker for selecting emergency fund target multiplier (3x-6x monthly income) with optional hard cap.
struct EmergencyMultiplierPicker: View {
    @Binding var multiplier: Double
    @Binding var hardCap: Decimal?
    let monthlyIncome: Decimal
    let currency: String

    @State private var hardCapEnabled: Bool = false
    @State private var hardCapText: String = ""

    private let multiplierOptions: [Double] = [3.0, 4.0, 5.0, 6.0]

    /// The calculated target based on multiplier alone
    private var calculatedTarget: Decimal {
        monthlyIncome * Decimal(multiplier)
    }

    /// The effective target considering the hard cap
    private var effectiveTarget: Decimal {
        if let cap = hardCap {
            return min(calculatedTarget, cap)
        }
        return calculatedTarget
    }

    /// Whether the hard cap is limiting the target
    private var isCapActive: Bool {
        guard let cap = hardCap else { return false }
        return cap < calculatedTarget
    }

    var body: some View {
        VStack(spacing: Spacing.sm) {
            segmentedPicker
            targetDisplay
            hardCapSection
        }
        .onAppear {
            // Initialize state from binding
            hardCapEnabled = hardCap != nil
            if let cap = hardCap {
                hardCapText = AmountFormatter.formatForEditing(cap)
            }
        }
    }
}

// MARK: - Subviews

private extension EmergencyMultiplierPicker {
    var segmentedPicker: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(multiplierOptions, id: \.self) { option in
                multiplierButton(option)
            }
        }
    }

    func multiplierButton(_ option: Double) -> some View {
        Button {
            withAnimation(SpringPreset.responsive) {
                multiplier = option
            }
            HapticManager.lightTap()
        } label: {
            Text("\(Int(option))×")
                .font(.subheadline)
                .fontWeight(multiplier == option ? .semibold : .regular)
                .foregroundStyle(multiplier == option ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.small)
                        .fill(multiplier == option ? Color.orange : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }

    var targetDisplay: some View {
        HStack {
            Text("Target:".localized)
                .font(.caption)
                .foregroundStyle(.secondary)

            if isCapActive {
                // Show capped target with strikethrough on original
                HStack(spacing: Spacing.xs) {
                    Text(AmountFormatter.formatForDisplay(calculatedTarget, currency: currency))
                        .font(.caption)
                        .strikethrough()
                        .foregroundStyle(.secondary)

                    Text(AmountFormatter.formatForDisplay(effectiveTarget, currency: currency))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.orange)
                }
                .contentTransition(.numericText())
                .animation(.easeOut(duration: AnimationDuration.appear), value: multiplier)
                .animation(.easeOut(duration: AnimationDuration.appear), value: hardCap)
            } else {
                Text(AmountFormatter.formatForDisplay(effectiveTarget, currency: currency))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.orange)
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: AnimationDuration.appear), value: multiplier)
                    .animation(.easeOut(duration: AnimationDuration.appear), value: hardCap)
            }

            Spacer()

            Text(multiplierDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .contentTransition(.interpolate)
                .animation(.easeOut(duration: AnimationDuration.appear), value: multiplier)
        }
    }

    var hardCapSection: some View {
        VStack(spacing: Spacing.sm) {
            // Toggle for enabling hard cap
            HStack {
                Toggle(isOn: $hardCapEnabled) {
                    Text("Set maximum".localized)
                        .font(.subheadline)
                }
                .tint(.orange)
                .accessibilityHint("Caps the emergency fund target at a fixed amount".localized)
                .onChange(of: hardCapEnabled) { _, enabled in
                    withAnimation(SpringPreset.responsive) {
                        if enabled {
                            // Default to calculated target when enabling
                            let defaultCap = calculatedTarget
                            hardCap = defaultCap
                            hardCapText = AmountFormatter.formatForEditing(defaultCap)
                        } else {
                            hardCap = nil
                            hardCapText = ""
                        }
                    }
                    HapticManager.selectionChanged()
                }
            }

            // Amount input when enabled
            if hardCapEnabled {
                HStack(spacing: Spacing.sm) {
                    Text("Max:".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: Spacing.xs) {
                        TextField("0", text: $hardCapText)
                            .font(.subheadline)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: hardCapText) { _, newValue in
                                let parsed = AmountFormatter.parse(newValue)
                                hardCap = parsed > 0 ? parsed : nil
                                if parsed <= 0 {
                                    hardCapEnabled = false
                                }
                            }
                            .accessibilityLabel("Maximum amount".localized)

                        Text(currency)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(Spacing.sm)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    var multiplierDescription: String {
        switch multiplier {
        case 3.0:
            return "Minimum recommended".localized
        case 4.0:
            return "Standard protection".localized
        case 5.0:
            return "Enhanced protection".localized
        case 6.0:
            return "Maximum security".localized
        default:
            return ""
        }
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        EmergencyMultiplierPicker(
            multiplier: .constant(3.0),
            hardCap: .constant(nil),
            monthlyIncome: 5000,
            currency: "USD"
        )

        EmergencyMultiplierPicker(
            multiplier: .constant(6.0),
            hardCap: .constant(25000),
            monthlyIncome: 5000,
            currency: "USD"
        )
    }
    .padding()
}
