import SwiftUI
import DesignSystem
import Domain
import SharedUI
import Utilities

struct SettingsAccountRow: View {
    let account: AccountEntry
    let currencyCode: String

    @ScaledMetric(relativeTo: .body) private var iconWidth = ComponentSize.iconContainer

    var body: some View {
        HStack {
            Image(systemName: account.accountType.icon)
                .foregroundStyle(account.accountType.color)
                .frame(width: iconWidth)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(account.name)
                    .foregroundStyle(.primary)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Spacing.xs) { details }
                    VStack(alignment: .leading, spacing: Spacing.xxs) { details }
                }
                .font(.caption)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .contentShape(.rect)
    }

    @ViewBuilder
    private var details: some View {
        Text(account.accountType.displayName)
            .foregroundStyle(.secondary)

        if account.isPrimarySavings {
            Text("Primary".localized)
                .foregroundStyle(DiamerisColors.accentPrimary)
        }

        if let multiplier = account.emergencyMultiplier {
            Text(emergencyTargetText(multiplier: multiplier))
                .foregroundStyle(DiamerisColors.accentSecondary)
        }
    }

    private func emergencyTargetText(multiplier: Double) -> String {
        let target = "\(multiplier.formatted())× \("income".localized)"
        guard let cap = account.emergencyHardCap else { return target }
        return "\(target) (\("max".localized) \(AmountFormatter.formatForDisplay(cap, currency: currencyCode)))"
    }
}
