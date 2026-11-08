import SwiftUI
import Domain
import DesignSystem
import Utilities
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

    @State private var showDeleteConfirmation = false
    @ScaledMetric(relativeTo: .title3) private var iconSize = IconSize.md

    private var displayAmount: Decimal {
        expense.displayAmount(for: displayFrequency)
    }

    private var contentStyle: HierarchicalShapeStyle {
        expense.isEnabled ? .primary : .secondary
    }

    public var body: some View {
        // The toggle sits beside the row button, not inside its label, so VoiceOver and
        // Switch Control can reach both controls.
        HStack(spacing: Spacing.sm) {
            Button {
                HapticManager.lightTap()
                onTap?()
            } label: {
                rowLabel
            }
            .buttonStyle(.plain)

            Toggle(expense.name, isOn: Binding(
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
        .contextMenu {
            if let onTap {
                Button {
                    HapticManager.lightTap()
                    onTap()
                } label: {
                    Label("Edit".localized, systemImage: "pencil")
                }
            }

            if onDelete != nil {
                Button(role: .destructive) {
                    HapticManager.warning()
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete".localized, systemImage: "trash")
                }
            }
        }
        .confirmationDialog(
            "Delete Expense".localized,
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete".localized, role: .destructive) {
                onDelete?()
            }
            Button("Cancel".localized, role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this expense? This action cannot be undone.".localized)
        }
    }

    private var rowLabel: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: expense.icon)
                .font(.title3)
                .foregroundStyle(contentStyle)
                .frame(width: iconSize, height: iconSize)
                .accessibilityHidden(true)

            Text(expense.name)
                .font(.body)
                .foregroundStyle(contentStyle)

            Spacer()

            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text(AmountFormatter.formatForDisplay(displayAmount, currency: currency))
                    .font(.body.monospacedDigit())
                    .foregroundStyle(contentStyle)

                if expense.frequency == .annual && displayFrequency == .monthly {
                    Text("(\("Annual".localized))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .contentShape(.rect)
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
                categoryId: ExpenseCategory.autoTransport.id
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
