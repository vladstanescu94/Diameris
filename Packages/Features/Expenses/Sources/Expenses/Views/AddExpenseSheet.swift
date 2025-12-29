import SwiftUI
import Domain
import DesignSystem
import SharedUI
import Utilities
import UIKit

/// Sheet for adding or editing an expense
public struct AddExpenseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: ExpensesViewModel

    @State private var input: ExpenseInput
    @State private var showDeleteConfirmation = false

    private let isEditing: Bool
    private let editingExpenseId: UUID?

    public init(viewModel: ExpensesViewModel, editingExpense: ExpenseDisplayItem? = nil) {
        self.viewModel = viewModel
        self.isEditing = editingExpense != nil
        self.editingExpenseId = editingExpense?.id
        self._input = State(initialValue: editingExpense.map { ExpenseInput(from: $0) } ?? ExpenseInput())
    }

    private var title: String {
        isEditing ? "Edit Expense".localized : "Add Expense".localized
    }

    private var monthlyEquivalent: Decimal {
        guard input.frequency == .annual else { return input.amount }
        return input.amount * Frequency.annual.monthlyMultiplier
    }

    public var body: some View {
        NavigationStack {
            Form {
                // Basic info
                Section {
                    TextField("Name".localized, text: $input.name)

                    CurrencyAmountField(
                        amount: $input.amount,
                        currency: $viewModel.currency,
                        showCurrencyPicker: false
                    )

                    FrequencyPicker(selection: $input.frequency)
                } header: {
                    Text("Details".localized)
                }

                // Monthly equivalent for annual expenses
                if input.frequency == .annual && input.amount > 0 {
                    Section {
                        HStack {
                            Text("Monthly Equivalent".localized)
                            Spacer()
                            Text(AmountFormatter.formatForDisplay(monthlyEquivalent, currency: viewModel.currency.rawValue))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Category
                Section {
                    CategoryPicker(
                        selection: $input.categoryId,
                        categories: viewModel.allCategories
                    )
                } header: {
                    Text("Category".localized)
                }

                // Icon picker
                Section {
                    IconPicker(selection: $input.icon)
                } header: {
                    Text("Icon".localized)
                }

                // Notes
                Section {
                    TextField("Notes".localized, text: Binding(
                        get: { input.notes ?? "" },
                        set: { input.notes = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .lineLimit(3...6)
                } header: {
                    Text("Notes".localized)
                }

                // Enable/disable toggle
                Section {
                    Toggle("Enabled".localized, isOn: $input.isEnabled)
                } footer: {
                    Text("Disabled expenses won't be included in your budget calculations.".localized)
                }

                // Delete button (only when editing)
                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            HapticManager.warning()
                            showDeleteConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Delete Expense".localized)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog(
                "Delete Expense".localized,
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete".localized, role: .destructive) {
                    HapticManager.warning()
                    if let id = editingExpenseId {
                        Task {
                            await viewModel.deleteExpense(id)
                        }
                    }
                    dismiss()
                }
                Button("Cancel".localized, role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this expense? This action cannot be undone.".localized)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) {
                        HapticManager.lightTap()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save".localized) {
                        HapticManager.success()
                        Task {
                            await viewModel.saveExpense(input)
                        }
                    }
                    .disabled(!input.isValid)
                }
            }
        }
    }
}

/// Simple icon picker for expenses
struct IconPicker: View {
    @Binding var selection: String

    private let icons = [
        "dollarsign.circle.fill",
        "cart.fill",
        "house.fill",
        "car.fill",
        "fuelpump.fill",
        "shield.fill",
        "heart.fill",
        "fork.knife",
        "cup.and.saucer.fill",
        "tshirt.fill",
        "pawprint.fill",
        "tv.fill",
        "gamecontroller.fill",
        "music.note",
        "film.fill",
        "airplane",
        "gift.fill",
        "creditcard.fill",
        "phone.fill",
        "wifi",
        "bolt.fill",
        "drop.fill",
        "leaf.fill",
        "wrench.fill",
        "hammer.fill",
        "paintbrush.fill",
        "bandage.fill",
        "pills.fill",
        "dumbbell.fill",
        "bicycle",
        "bus.fill",
        "train.side.front.car",
        "book.fill",
        "graduationcap.fill",
        "briefcase.fill",
        "building.2.fill",
        "sparkles"
    ]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: Spacing.sm) {
            ForEach(icons, id: \.self) { icon in
                Button {
                    HapticManager.lightTap()
                    selection = icon
                } label: {
                    Image(systemName: icon)
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(selection == icon ? Color.accentColor.opacity(0.2) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(icon)
            }
        }
    }
}

#Preview {
    AddExpenseSheet(viewModel: ExpensesViewModel())
}
