import SwiftUI
import DesignSystem
import SharedUI
import Utilities

/// Card displaying emergency fund progress.
struct EmergencyProgressCard: View {
    let currentBalance: Decimal
    let target: Decimal
    let progress: Double
    let multiplier: Double
    let emergencyHardCap: Decimal?
    let currency: Currency

    var body: some View {
        HStack(spacing: Spacing.md) {
            progressRing
            fundInfo
            Spacer()
        }
        .glassCard()
    }
}

// MARK: - Subviews

private extension EmergencyProgressCard {
    var progressRing: some View {
        ProgressRing.large(
            progress: progress,
            showLabel: true,
            color: progressColor
        )
    }

    var fundInfo: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Label {
                Text("Emergency Fund".localized)
                    .font(.headline)
            } icon: {
                Image(systemName: "shield.fill")
                    .foregroundStyle(progressColor)
            }

            Text(balanceText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(targetText)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    var progressColor: Color {
        if progress >= 1.0 {
            return DiamerisColors.positive
        } else if progress >= 0.5 {
            return DiamerisColors.accentSecondary
        } else {
            return DiamerisColors.warning
        }
    }

    var balanceText: String {
        let current = AmountFormatter.formatForDisplay(currentBalance, currency: currency.rawValue)
        let targetFormatted = AmountFormatter.formatForDisplay(target, currency: currency.rawValue)
        return "\(current) / \(targetFormatted)"
    }

    var targetText: String {
        let multiplierInt = Int(multiplier)
        if let cap = emergencyHardCap {
            let capFormatted = AmountFormatter.formatForDisplay(cap, currency: currency.rawValue)
            return String(
                localized: "Target: \(multiplierInt)× monthly income (capped at \(capFormatted))",
                bundle: .module
            )
        }
        return String(
            localized: "Target: \(multiplierInt)× monthly income",
            bundle: .module
        )
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        EmergencyProgressCard(
            currentBalance: 37056,
            target: 42909,
            progress: 0.86,
            multiplier: 3.0,
            emergencyHardCap: nil,
            currency: .ron
        )

        EmergencyProgressCard(
            currentBalance: 35000,
            target: 40000,
            progress: 0.875,
            multiplier: 3.0,
            emergencyHardCap: 40000,
            currency: .ron
        )

        EmergencyProgressCard(
            currentBalance: 42909,
            target: 42909,
            progress: 1.0,
            multiplier: 3.0,
            emergencyHardCap: nil,
            currency: .ron
        )

        EmergencyProgressCard(
            currentBalance: 10000,
            target: 42909,
            progress: 0.23,
            multiplier: 3.0,
            emergencyHardCap: nil,
            currency: .ron
        )
    }
    .padding()
}
