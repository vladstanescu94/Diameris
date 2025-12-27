import SwiftUI
import DesignSystem
import Utilities

/// A card displaying a single transfer in the transfer plan.
public struct TransferCard: View {
    let title: String
    let subtitle: String?
    let amount: Decimal
    let currency: String
    let icon: String
    let iconColor: Color
    let progressInfo: TransferPlan.GoalAllocation.ProgressInfo?
    let isComplete: Bool

    @State private var appeared = false

    public init(
        title: String,
        subtitle: String? = nil,
        amount: Decimal,
        currency: String,
        icon: String,
        iconColor: Color = DiamerisColors.accentSecondary,
        progressInfo: TransferPlan.GoalAllocation.ProgressInfo? = nil,
        isComplete: Bool = false
    ) {
        self.title = title
        self.subtitle = subtitle
        self.amount = amount
        self.currency = currency
        self.icon = icon
        self.iconColor = iconColor
        self.progressInfo = progressInfo
        self.isComplete = isComplete
    }

    public var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(iconColor)
            }
            .accessibilityHidden(true)

            // Content
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack {
                    Text(title)
                        .font(.headline)

                    if isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                            .accessibilityLabel("Complete".localized)
                    }
                }

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Progress info
                if let progress = progressInfo {
                    HStack(spacing: Spacing.xs) {
                        Text("\(Int(progress.currentPercent))%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)

                        Text("\(Int(progress.afterPercent))%")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(iconColor)
                    }
                }
            }

            Spacer()

            // Amount
            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text(AmountFormatter.formatForDisplay(amount, currency: currency))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(amount > 0 ? .primary : .tertiary)

                if amount > 0 {
                    // Copy button hint
                    Image(systemName: "doc.on.doc")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(Spacing.md)
        .glassCard()
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : SlideOffset.standard)
        .onAppear {
            withAnimation(SpringPreset.smooth) {
                appeared = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        var description = "\(title), \(AmountFormatter.formatForDisplay(amount, currency: currency))"
        if let subtitle = subtitle {
            description += ", \(subtitle)"
        }
        if let progress = progressInfo {
            description += ", progress from \(Int(progress.currentPercent)) to \(Int(progress.afterPercent)) percent"
        }
        if isComplete {
            description += ", goal complete"
        }
        return description
    }
}

// MARK: - Convenience Initializers

extension TransferCard {
    /// Create from a goal allocation
    public init(
        allocation: TransferPlan.GoalAllocation,
        currency: String
    ) {
        self.init(
            title: allocation.goalName,
            subtitle: allocation.isComplete ? "Goal complete this month!".localized : nil,
            amount: allocation.amount,
            currency: currency,
            icon: allocation.goalIcon,
            iconColor: allocation.accountType == .savings ? DiamerisColors.accentSecondary : DiamerisColors.accentPrimary,
            progressInfo: allocation.targetAmount != nil ? .init(
                currentPercent: allocation.progressBefore * 100,
                afterPercent: allocation.progressAfter * 100
            ) : nil,
            isComplete: allocation.isComplete
        )
    }

    /// Create for flexible spending
    public static func flexibleSpending(
        amount: Decimal,
        currency: String
    ) -> TransferCard {
        TransferCard(
            title: "Personal".localized,
            subtitle: "Flexible spending money".localized,
            amount: amount,
            currency: currency,
            icon: "person.fill",
            iconColor: DiamerisColors.accentPrimary
        )
    }

    /// Create for primary account (stays for expenses)
    public static func primaryAccount(
        amount: Decimal,
        currency: String
    ) -> TransferCard {
        TransferCard(
            title: "Stays in Main".localized,
            subtitle: "For automatic payments".localized,
            amount: amount,
            currency: currency,
            icon: "building.columns.fill",
            iconColor: .secondary
        )
    }

    /// Create for account expense transfer
    public static func expenseTransfer(
        transfer: TransferPlan.AccountExpenseTransfer,
        currency: String
    ) -> TransferCard {
        let subtitle = transfer.expenseNames.joined(separator: ", ")
        return TransferCard(
            title: transfer.accountName,
            subtitle: subtitle,
            amount: transfer.amount,
            currency: currency,
            icon: "creditcard.fill",
            iconColor: .purple
        )
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        TransferCard(
            title: "Emergency Fund",
            subtitle: "Building safety net",
            amount: 2751,
            currency: "RON",
            icon: "shield.checkered",
            iconColor: DiamerisColors.accentSecondary,
            progressInfo: .init(currentPercent: 86, afterPercent: 92)
        )

        TransferCard(
            title: "Savings",
            subtitle: nil,
            amount: 0,
            currency: "RON",
            icon: "banknote.fill",
            iconColor: DiamerisColors.accentPrimary
        )

        TransferCard.flexibleSpending(amount: 1497, currency: "RON")

        TransferCard.primaryAccount(amount: 7055, currency: "RON")
    }
    .padding()
}
