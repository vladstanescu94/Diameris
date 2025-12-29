import SwiftUI
import Domain
import DesignSystem
import Utilities
import UIKit

/// Expandable card showing expenses grouped by category
public struct ExpenseCategoryCard: View {
    let group: ExpenseGroup
    let displayFrequency: Frequency
    let currency: String
    @Binding var isExpanded: Bool
    var onExpenseTap: ((ExpenseDisplayItem) -> Void)?
    var onExpenseToggle: ((ExpenseDisplayItem, Bool) -> Void)?
    var onExpenseDelete: ((ExpenseDisplayItem) -> Void)?

    public init(
        group: ExpenseGroup,
        displayFrequency: Frequency,
        currency: String,
        isExpanded: Binding<Bool>,
        onExpenseTap: ((ExpenseDisplayItem) -> Void)? = nil,
        onExpenseToggle: ((ExpenseDisplayItem, Bool) -> Void)? = nil,
        onExpenseDelete: ((ExpenseDisplayItem) -> Void)? = nil
    ) {
        self.group = group
        self.displayFrequency = displayFrequency
        self.currency = currency
        self._isExpanded = isExpanded
        self.onExpenseTap = onExpenseTap
        self.onExpenseToggle = onExpenseToggle
        self.onExpenseDelete = onExpenseDelete
    }

    private var displayTotal: Decimal {
        displayFrequency == .monthly ? group.totalMonthly : group.totalAnnual
    }

    private var categoryName: String {
        group.category?.name ?? "Uncategorized".localized
    }

    private var categoryIcon: String {
        group.category?.icon ?? "questionmark.circle.fill"
    }

    private var categoryColor: Color {
        if let hex = group.category?.colorHex {
            return Color(hex: hex) ?? .gray
        }
        return .gray
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            Button {
                HapticManager.lightTap()
                withAnimation(SpringPreset.snappy) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: Spacing.sm) {
                    // Category icon
                    Image(systemName: categoryIcon)
                        .font(.title2)
                        .foregroundStyle(categoryColor)
                        .frame(width: IconSize.lg, height: IconSize.lg)

                    // Category name and count
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(categoryName)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text("\(group.enabledCount)/\(group.expenses.count) " + "enabled".localized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Total amount
                    Text(AmountFormatter.formatForDisplay(displayTotal, currency: currency))
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.primary)

                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(Spacing.md)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                Divider()
                    .padding(.horizontal, Spacing.md)

                LazyVStack(spacing: 0) {
                    ForEach(group.expenses) { expense in
                        ExpenseItemRow(
                            expense: expense,
                            displayFrequency: displayFrequency,
                            currency: currency,
                            onToggle: { enabled in
                                onExpenseToggle?(expense, enabled)
                            },
                            onTap: {
                                onExpenseTap?(expense)
                            },
                            onDelete: {
                                onExpenseDelete?(expense)
                            }
                        )
                        .padding(.horizontal, Spacing.md)

                        if expense.id != group.expenses.last?.id {
                            Divider()
                                .padding(.leading, Spacing.md + IconSize.md + Spacing.sm)
                        }
                    }
                }
                .padding(.vertical, Spacing.sm)
            }
        }
        .glassEffect(in: .rect(cornerRadius: CornerRadius.large))
    }
}

// Color extension for hex parsing
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        guard hexSanitized.count == 6 else { return nil }

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        self.init(
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0
        )
    }
}

#Preview {
    @Previewable @State var isExpanded = true

    ScrollView {
        VStack(spacing: Spacing.md) {
            ExpenseCategoryCard(
                group: ExpenseGroup(
                    category: ExpenseCategory.autoTransport,
                    expenses: [
                        ExpenseDisplayItem(
                            name: "Gas",
                            amount: 300,
                            frequency: .monthly,
                            icon: "car.fill",
                            categoryId: ExpenseCategory.autoTransport.id
                        ),
                        ExpenseDisplayItem(
                            name: "Car Insurance",
                            amount: 2400,
                            frequency: .annual,
                            icon: "shield.fill",
                            categoryId: ExpenseCategory.autoTransport.id,
                            isEnabled: false
                        )
                    ]
                ),
                displayFrequency: .monthly,
                currency: "USD",
                isExpanded: $isExpanded
            )

            ExpenseCategoryCard(
                group: ExpenseGroup(
                    category: nil,
                    expenses: [
                        ExpenseDisplayItem(
                            name: "Random Expense",
                            amount: 50,
                            frequency: .monthly,
                            icon: "dollarsign.circle"
                        )
                    ]
                ),
                displayFrequency: .monthly,
                currency: "USD",
                isExpanded: .constant(true)
            )
        }
        .padding()
    }
}
