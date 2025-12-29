import SwiftUI
import Domain
import DesignSystem
import Utilities
import UIKit

/// Row displaying a single expense item
public struct ExpenseItemRow: View {
    let expense: ExpenseDisplayItem
    let displayFrequency: Frequency
    let currency: String
    var onToggle: ((Bool) -> Void)?
    var onTap: (() -> Void)?
    var onDelete: (() -> Void)?

    public init(
        expense: ExpenseDisplayItem,
        displayFrequency: Frequency,
        currency: String,
        onToggle: ((Bool) -> Void)? = nil,
        onTap: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self.expense = expense
        self.displayFrequency = displayFrequency
        self.currency = currency
        self.onToggle = onToggle
        self.onTap = onTap
        self.onDelete = onDelete
    }

    private var displayAmount: Decimal {
        displayFrequency == .monthly ? expense.monthlyAmount : expense.annualAmount
    }

    public var body: some View {
        Button {
            HapticManager.lightTap()
            onTap?()
        } label: {
            HStack(spacing: Spacing.sm) {
                // Icon
                Image(systemName: expense.icon)
                    .font(.title3)
                    .foregroundStyle(expense.isEnabled ? .primary : .secondary)
                    .frame(width: IconSize.md, height: IconSize.md)

                // Name and subcategory
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(expense.name)
                        .font(.body)
                        .foregroundStyle(expense.isEnabled ? .primary : .secondary)

                    if let subcategory = expense.subcategory {
                        Text(subcategory.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Amount and frequency indicator
                VStack(alignment: .trailing, spacing: Spacing.xxs) {
                    Text(AmountFormatter.formatForDisplay(displayAmount, currency: currency))
                        .font(.body.monospacedDigit())
                        .foregroundStyle(expense.isEnabled ? .primary : .secondary)

                    if expense.frequency == .annual && displayFrequency == .monthly {
                        Text("(\("Annual".localized))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                // Toggle
                Toggle("", isOn: Binding(
                    get: { expense.isEnabled },
                    set: { newValue in
                        HapticManager.selectionChanged()
                        onToggle?(newValue)
                    }
                ))
                .labelsHidden()
                .tint(.accentColor)
            }
            .padding(.vertical, Spacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if let onDelete {
                Button(role: .destructive) {
                    HapticManager.warning()
                    onDelete()
                } label: {
                    Label("Delete".localized, systemImage: "trash")
                }
            }
        }
    }
}

#Preview {
    List {
        ExpenseItemRow(
            expense: ExpenseDisplayItem(
                name: "Gas",
                amount: 300,
                frequency: .monthly,
                icon: "car.fill",
                categoryId: ExpenseCategory.autoTransport.id,
                subcategoryId: Subcategory.defaults(for: ExpenseCategory.autoTransport.id).first?.id
            ),
            displayFrequency: .monthly,
            currency: "USD",
            onToggle: { _ in },
            onTap: {},
            onDelete: {}
        )

        ExpenseItemRow(
            expense: ExpenseDisplayItem(
                name: "Car Insurance",
                amount: 2400,
                frequency: .annual,
                icon: "shield.fill",
                categoryId: ExpenseCategory.autoTransport.id,
                isEnabled: false
            ),
            displayFrequency: .monthly,
            currency: "USD",
            onToggle: { _ in },
            onTap: {},
            onDelete: {}
        )
    }
}
