import SwiftUI
import DesignSystem
import SharedUI
import Domain
import Utilities

/// Step 3: Review and confirm the transfer plan.
struct TransferPlanStep: View {
    let income: Decimal
    let expenses: Decimal
    let transferPlan: TransferPlan
    let currency: Currency
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    TransferPlanSummary(
                        income: income,
                        expenses: expenses,
                        availableIncome: transferPlan.availableIncome,
                        currency: currency
                    )

                    TransferPlanTransfers(
                        transferPlan: transferPlan,
                        currency: currency
                    )

                    PrimaryAccountRow(
                        amount: transferPlan.remainsInPrimary,
                        currency: currency
                    )

                    TransferPlanVerificationBadge(isBalanced: transferPlan.isBalanced)
                }
                .padding(.horizontal, Spacing.lg)
            }
            .scrollIndicators(.hidden)

            Button(action: onComplete) {
                Label("Done - I made the transfers".localized, systemImage: "checkmark")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.glassProminent)
            .padding(.horizontal, Spacing.lg)
        }
        .padding(.vertical, Spacing.md)
    }
}

// MARK: - Transfer Plan Summary

private struct TransferPlanSummary: View {
    let income: Decimal
    let expenses: Decimal
    let availableIncome: Decimal
    let currency: Currency

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label {
                Text("Your Transfer Plan".localized)
                    .font(.headline)
            } icon: {
                Image(systemName: "list.clipboard.fill")
                    .foregroundStyle(DiamerisColors.accentPrimary)
            }

            HStack {
                Text("Income".localized)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatAmount(income))
            }
            .font(.subheadline)

            HStack {
                Text("Expenses".localized)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatAmount(expenses, negative: true))
                    .foregroundStyle(DiamerisColors.negative)
            }
            .font(.subheadline)

            Divider()

            HStack {
                Text("Available".localized)
                    .bold()
                Spacer()
                Text(formatAmount(availableIncome))
                    .bold()
            }
            .font(.subheadline)
        }
        .glassCard()
    }

    private func formatAmount(_ amount: Decimal, negative: Bool = false) -> String {
        let prefix = negative && amount > 0 ? "-" : ""
        return prefix + AmountFormatter.formatForDisplay(amount, currency: currency.rawValue)
    }
}

// MARK: - Transfer Plan Transfers

private struct TransferPlanTransfers: View {
    let transferPlan: TransferPlan
    let currency: Currency

    private var hasTransfers: Bool {
        transferPlan.hasAccountAllocations ||
        !transferPlan.accountExpenseTransfers.isEmpty ||
        transferPlan.remainingMoney > 0
    }

    var body: some View {
        if hasTransfers {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Transfers to make".localized)
                    .font(.headline)

                ForEach(transferPlan.accountAllocations) { allocation in
                    AllocationTransferRow(allocation: allocation, currency: currency)
                }

                ForEach(transferPlan.accountExpenseTransfers) { expenseTransfer in
                    ExpenseTransferRow(transfer: expenseTransfer, currency: currency)
                }

                if transferPlan.remainingMoney > 0 {
                    RemainingMoneyRow(
                        amount: transferPlan.remainingMoney,
                        destination: transferPlan.remainingDestination,
                        currency: currency
                    )
                }
            }
            .glassCard()
        }
    }
}

// MARK: - Allocation Transfer Row

private struct AllocationTransferRow: View {
    let allocation: TransferPlan.AccountAllocation
    let currency: Currency

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: allocation.icon)
                .font(.body)
                .foregroundStyle(iconColor)
                .frame(width: ComponentSize.iconContainer)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(allocation.accountName)
                    .font(.subheadline)
                    .bold()

                if let note = transferNote {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text("+\(formattedAmount)")
                .font(.subheadline)
                .bold()
                .foregroundStyle(DiamerisColors.positive)
        }
    }

    private var formattedAmount: String {
        AmountFormatter.formatForDisplay(allocation.amount, currency: currency.rawValue)
    }

    private var transferNote: String? {
        if allocation.accountType == .emergency && allocation.isComplete {
            return "Completes fund to 100%!".localized
        }
        return allocation.progressChangeDisplay
    }

    private var iconColor: Color {
        switch allocation.accountType {
        case .primary: .secondary
        case .emergency: DiamerisColors.warning
        case .savings: DiamerisColors.accentPrimary
        case .personal: DiamerisColors.accentSecondary
        default: .secondary
        }
    }
}

// MARK: - Expense Transfer Row

private struct ExpenseTransferRow: View {
    let transfer: TransferPlan.AccountExpenseTransfer
    let currency: Currency

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "arrow.right.circle.fill")
                .font(.body)
                .foregroundStyle(DiamerisColors.accentSecondary)
                .frame(width: ComponentSize.iconContainer)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(String.localized("Transfer to \(transfer.accountName)"))
                    .font(.subheadline)
                    .bold()

                Text(String.localized("for \(transfer.expenseNames.joined(separator: ", "))"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("+\(AmountFormatter.formatForDisplay(transfer.amount, currency: currency.rawValue))")
                .font(.subheadline)
                .bold()
                .foregroundStyle(DiamerisColors.positive)
        }
    }
}

// MARK: - Remaining Money Row

private struct RemainingMoneyRow: View {
    let amount: Decimal
    let destination: RemainingMoneyDestination
    let currency: Currency

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: ComponentSize.iconContainer)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(name)
                    .font(.subheadline)
                    .bold()

                Text("remaining money".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("+\(AmountFormatter.formatForDisplay(amount, currency: currency.rawValue))")
                .font(.subheadline)
                .bold()
                .foregroundStyle(DiamerisColors.positive)
        }
    }

    private var icon: String {
        switch destination {
        case .primarySavings: "banknote.fill"
        case .personal: "person.fill"
        case .primary: "building.columns.fill"
        }
    }

    private var color: Color {
        switch destination {
        case .primarySavings: DiamerisColors.accentPrimary
        case .personal: DiamerisColors.accentSecondary
        case .primary: .secondary
        }
    }

    private var name: String {
        switch destination {
        case .primarySavings: "Savings".localized
        case .personal: "Personal".localized
        case .primary: "Primary".localized
        }
    }
}

// MARK: - Primary Account Row

private struct PrimaryAccountRow: View {
    let amount: Decimal
    let currency: Currency

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "building.columns.fill")
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: ComponentSize.iconContainer)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Primary".localized)
                    .font(.subheadline)
                    .bold()

                Text("stays for automatic payments".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(AmountFormatter.formatForDisplay(amount, currency: currency.rawValue))
                .font(.subheadline)
                .bold()
        }
        .glassCard()
    }
}

// MARK: - Verification Badge

private struct TransferPlanVerificationBadge: View {
    let isBalanced: Bool

    var body: some View {
        if isBalanced {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(DiamerisColors.positive)

                Text("All amounts add up correctly".localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(Spacing.sm)
            .frame(maxWidth: .infinity)
            .background(DiamerisColors.positive.opacity(0.1), in: RoundedRectangle(cornerRadius: CornerRadius.medium))
        }
    }
}

#Preview {
    let plan = TransferPlan(
        income: 14303,
        totalExpenses: 7205,
        availableIncome: 7098,
        totalSavings: 1774,
        accountAllocations: [],
        remainsInPrimary: 5000,
        accountExpenseTransfers: [],
        remainingMoney: 573,
        remainingDestination: .personal,
        isBalanced: true
    )

    TransferPlanStep(
        income: 14303,
        expenses: 7205,
        transferPlan: plan,
        currency: .ron,
        onComplete: {}
    )
}
