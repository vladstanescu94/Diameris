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
                    summarySection
                    transfersSection
                    primaryAccountSection
                    verificationBadge
                }
                .padding(.horizontal, Spacing.lg)
            }

            completeButton
                .padding(.horizontal, Spacing.lg)
        }
        .padding(.vertical, Spacing.md)
    }
}

// MARK: - Subviews

private extension TransferPlanStep {
    var summarySection: some View {
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
                    .fontWeight(.medium)
                Spacer()
                Text(formatAmount(transferPlan.availableIncome))
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
        }
        .glassCard()
    }

    @ViewBuilder
    var transfersSection: some View {
        let hasTransfers = transferPlan.hasAccountAllocations ||
                          !transferPlan.accountExpenseTransfers.isEmpty ||
                          transferPlan.remainingMoney > 0

        if hasTransfers {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Transfers to make".localized)
                    .font(.headline)

                // Savings allocations (emergency, savings)
                ForEach(transferPlan.accountAllocations) { allocation in
                    transferRow(for: allocation)
                }

                // Expense-linked account transfers (e.g., Food → Joint)
                ForEach(transferPlan.accountExpenseTransfers) { expenseTransfer in
                    expenseTransferRow(for: expenseTransfer)
                }

                // Show remaining money destination
                if transferPlan.remainingMoney > 0 {
                    remainingMoneyRow
                }
            }
            .glassCard()
        }
    }

    func expenseTransferRow(for transfer: TransferPlan.AccountExpenseTransfer) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "arrow.right.circle.fill")
                .font(.body)
                .foregroundStyle(DiamerisColors.accentSecondary)
                .frame(width: ComponentSize.iconContainer)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(transferToAccountText(transfer.accountName))
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(expenseNamesText(transfer.expenseNames))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("+\(formatAmount(transfer.amount))")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(DiamerisColors.positive)
        }
    }

    func transferToAccountText(_ accountName: String) -> String {
        String.localized("Transfer to \(accountName)")
    }

    func expenseNamesText(_ names: [String]) -> String {
        String.localized("for \(names.joined(separator: ", "))")
    }

    func transferRow(for allocation: TransferPlan.AccountAllocation) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: allocation.icon)
                .font(.body)
                .foregroundStyle(iconColor(for: allocation.accountType))
                .frame(width: ComponentSize.iconContainer)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(allocation.accountName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let note = transferNote(for: allocation) {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text("+\(formatAmount(allocation.amount))")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(DiamerisColors.positive)
        }
    }

    var remainingMoneyRow: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: iconForRemainingDestination)
                .font(.body)
                .foregroundStyle(colorForRemainingDestination)
                .frame(width: ComponentSize.iconContainer)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(nameForRemainingDestination)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("remaining money".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("+\(formatAmount(transferPlan.remainingMoney))")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(DiamerisColors.positive)
        }
    }

    var primaryAccountSection: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "building.columns.fill")
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: ComponentSize.iconContainer)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Primary".localized)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("stays for automatic payments".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(formatAmount(transferPlan.remainsInPrimary))
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .glassCard()
    }

    func transferNote(for allocation: TransferPlan.AccountAllocation) -> String? {
        // Check if emergency fund will be complete after this transfer
        if allocation.accountType == .emergency && allocation.isComplete {
            return "Completes fund to 100%!".localized
        }
        if let progressChange = allocation.progressChangeDisplay {
            return progressChange
        }
        return nil
    }

    func iconColor(for type: AccountType) -> Color {
        switch type {
        case .primary:
            return .secondary
        case .emergency:
            return DiamerisColors.warning
        case .savings:
            return DiamerisColors.accentPrimary
        case .personal:
            return DiamerisColors.accentSecondary
        default:
            return .secondary
        }
    }

    var iconForRemainingDestination: String {
        switch transferPlan.remainingDestination {
        case .primarySavings:
            return "banknote.fill"
        case .personal:
            return "person.fill"
        case .primary:
            return "building.columns.fill"
        }
    }

    var colorForRemainingDestination: Color {
        switch transferPlan.remainingDestination {
        case .primarySavings:
            return DiamerisColors.accentPrimary
        case .personal:
            return DiamerisColors.accentSecondary
        case .primary:
            return .secondary
        }
    }

    var nameForRemainingDestination: String {
        switch transferPlan.remainingDestination {
        case .primarySavings:
            return "Savings".localized
        case .personal:
            return "Personal".localized
        case .primary:
            return "Primary".localized
        }
    }

    @ViewBuilder
    var verificationBadge: some View {
        if transferPlan.isBalanced {
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

    var completeButton: some View {
        Button {
            onComplete()
        } label: {
            Label("Done - I made the transfers".localized, systemImage: "checkmark")
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.glassProminent)
    }

    func formatAmount(_ amount: Decimal, negative: Bool = false) -> String {
        let prefix = negative && amount > 0 ? "-" : ""
        return prefix + AmountFormatter.formatForDisplay(amount, currency: currency.rawValue)
    }
}

#Preview {
    // Create a mock transfer plan - simpler version for preview
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
