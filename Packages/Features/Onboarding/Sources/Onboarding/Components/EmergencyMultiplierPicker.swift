import SwiftUI
import DesignSystem
import Utilities
import Domain

/// Emergency fund target as 3–6 months of income, with an optional hard cap.
struct EmergencyMultiplierPicker: View {
    @Binding var multiplier: Double
    @Binding var hardCap: Decimal?
    let monthlyIncome: Decimal
    let currency: String

    @State private var hardCapEnabled: Bool = false
    @State private var hardCapText: String = ""

    /// Months of income offered as emergency fund targets.
    static let multiplierOptions: [Double] = [3, 4, 5, 6]
    static let defaultMultiplier = multiplierOptions[0]

    /// Target from the multiplier alone (Domain calculation, ignoring the cap).
    private var calculatedTarget: Decimal {
        AccountEntry.emergency(multiplier: multiplier)
            .uncappedEmergencyTarget(monthlyIncome: monthlyIncome) ?? 0
    }

    /// Target after applying the hard cap (Domain calculation).
    private var effectiveTarget: Decimal {
        AccountEntry.emergency(multiplier: multiplier, hardCap: hardCap)
            .emergencyTarget(monthlyIncome: monthlyIncome) ?? 0
    }

    private var isCapActive: Bool {
        effectiveTarget < calculatedTarget
    }

    var body: some View {
        VStack(spacing: Spacing.sm) {
            segmentedPicker
            targetDisplay
            hardCapSection
        }
        .onAppear {
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
        Picker("Target: months of income".localized, selection: $multiplier) {
            ForEach(Self.multiplierOptions, id: \.self) { option in
                Text(verbatim: "\(Int(option))×").tag(option)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: multiplier) {
            HapticManager.lightTap()
        }
    }

    var targetDisplay: some View {
        HStack {
            Text("Target:".localized)
                .font(.caption)
                .foregroundStyle(.secondary)

            if isCapActive {
                HStack(spacing: Spacing.xs) {
                    Text(AmountFormatter.formatForDisplay(calculatedTarget, currency: currency))
                        .font(.caption)
                        .strikethrough()
                        .foregroundStyle(.secondary)

                    Text(AmountFormatter.formatForDisplay(effectiveTarget, currency: currency))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(String(
                    localized: "\(AmountFormatter.formatForDisplay(effectiveTarget, currency: currency)), capped from \(AmountFormatter.formatForDisplay(calculatedTarget, currency: currency))",
                    bundle: .module
                ))
                .contentTransition(.numericText())
                .animation(.easeOut(duration: AnimationDuration.appear), value: multiplier)
                .animation(.easeOut(duration: AnimationDuration.appear), value: hardCap)
            } else {
                Text(AmountFormatter.formatForDisplay(effectiveTarget, currency: currency))
                    .font(.caption)
                    .fontWeight(.medium)
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: AnimationDuration.appear), value: multiplier)
                    .animation(.easeOut(duration: AnimationDuration.appear), value: hardCap)
            }

            Spacer()

            Text(multiplierDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
                .contentTransition(.interpolate)
                .animation(.easeOut(duration: AnimationDuration.appear), value: multiplier)
        }
    }

    var hardCapSection: some View {
        VStack(spacing: Spacing.sm) {
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
                                // Clearing the field removes the cap but keeps it open for retyping.
                                let parsed = AmountFormatter.parse(newValue)
                                hardCap = parsed > 0 ? parsed : nil
                            }
                            .accessibilityLabel("Maximum amount".localized)

                        Text(currency)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(Spacing.sm)
                    .background(Color.secondary.opacity(Opacity.faint))
                    .clipShape(.rect(cornerRadius: CornerRadius.small))
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
