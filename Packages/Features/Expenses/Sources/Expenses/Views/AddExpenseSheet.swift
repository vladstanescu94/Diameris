import SwiftUI
import Domain
import DesignSystem
import SharedUI
import Utilities
public struct AddExpenseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: ExpensesViewModel

    @State private var input: ExpenseInput
    @State private var notesText: String = ""
    @State private var showDeleteConfirmation = false
    @State private var showAddCategory = false
    @State private var isSaving = false

    private let isEditing: Bool
    private let editingExpenseId: UUID?

    public init(viewModel: ExpensesViewModel, editingExpense: ExpenseDisplayItem? = nil) {
        self.viewModel = viewModel
        self.isEditing = editingExpense != nil
        self.editingExpenseId = editingExpense?.id
        let expenseInput = editingExpense.map { ExpenseInput(from: $0) } ?? ExpenseInput()
        self._input = State(initialValue: expenseInput)
        self._notesText = State(initialValue: editingExpense?.notes ?? "")
    }

    /// An empty name on a fresh form isn't flagged; the disabled Save button already says enough.
    private var visibleValidationMessage: String? {
        guard let error = input.validationError else { return nil }
        if error == .nameMissing && input.name.isEmpty { return nil }
        return error.message
    }

    private var title: String {
        isEditing ? "Edit Expense".localized : "Add Expense".localized
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name".localized, text: $input.name)
                } header: {
                    Text("Details".localized)
                }

                // The field draws its own glass card, so it replaces the row rather than sitting in one.
                Section {
                    CurrencyAmountField(
                        amount: $input.amount,
                        currency: $viewModel.currency,
                        showCurrencyPicker: false
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section {
                    FrequencyPicker(selection: $input.frequency)
                } footer: {
                    if let message = visibleValidationMessage {
                        Text(message)
                            .foregroundStyle(DiamerisColors.negative)
                    }
                }

                if input.frequency == .annual && input.amount > 0 {
                    Section {
                        LabeledContent(
                            "Monthly Equivalent".localized,
                            value: AmountFormatter.formatForDisplay(input.monthlyAmount, currency: viewModel.currency.rawValue)
                        )
                    }
                }

                Section {
                    CategoryPicker(
                        selection: $input.categoryId,
                        categories: viewModel.allCategories
                    )

                    Button {
                        HapticManager.lightTap()
                        showAddCategory = true
                    } label: {
                        Label("New Category...".localized, systemImage: "plus.circle")
                    }
                } header: {
                    Text("Category".localized)
                }

                if !viewModel.accounts.isEmpty {
                    Section {
                        Picker("Pay From".localized, selection: $input.linkedAccountId) {
                            Text("Primary".localized).tag(nil as UUID?)
                            ForEach(viewModel.accounts.filter { !$0.isPrimary }) { account in
                                Label(account.name, systemImage: account.accountType.icon)
                                    .tag(account.id as UUID?)
                            }
                        }
                    } header: {
                        Text("Account".localized)
                    } footer: {
                        Text("Choose which account this expense is paid from.".localized)
                    }
                }

                Section {
                    IconPicker(selection: $input.icon)
                } header: {
                    Text("Icon".localized)
                }

                Section {
                    TextField("Notes".localized, text: $notesText, axis: .vertical)
                        .lineLimit(3...6)
                        .onChange(of: notesText) { _, newValue in
                            input.notes = newValue.isEmpty ? nil : newValue
                        }
                } header: {
                    Text("Notes".localized)
                }

                Section {
                    Toggle("Enabled".localized, isOn: $input.isEnabled)
                } footer: {
                    Text("Disabled expenses won't be included in your budget calculations.".localized)
                }

                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            HapticManager.warning()
                            showDeleteConfirmation = true
                        } label: {
                            Text("Delete Expense".localized)
                                .frame(maxWidth: .infinity)
                        }
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
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) {
                        HapticManager.lightTap()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save".localized) {
                        // Guard against a double tap saving the same new expense twice.
                        guard !isSaving else { return }
                        isSaving = true
                        HapticManager.success()
                        Task {
                            await viewModel.saveExpense(input)
                        }
                    }
                    .disabled(!input.isValid || isSaving)
                }
            }
            .sheet(isPresented: $showAddCategory) {
                AddCategorySheet(viewModel: viewModel, onCategoryCreated: { categoryId in
                    input.categoryId = categoryId
                })
            }
        }
    }
}

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
        LazyVGrid(columns: [GridItem(.adaptive(minimum: ComponentSize.minTouchTarget))], spacing: Spacing.sm) {
            ForEach(icons, id: \.self) { icon in
                Button {
                    HapticManager.lightTap()
                    selection = icon
                } label: {
                    Image(systemName: icon)
                        .font(.title2)
                        .frame(width: ComponentSize.minTouchTarget, height: ComponentSize.minTouchTarget)
                        .foregroundStyle(selection == icon ? Color.accentColor : Color.primary)
                        .background(selection == icon ? Color.accentColor.opacity(Opacity.light) : Color.clear)
                        .clipShape(.rect(cornerRadius: CornerRadius.small))
                }
                .buttonStyle(.plain)
                // No explicit label: SF Symbols supply readable names ("Cart", "House"),
                // unlike the raw symbol identifier.
                .accessibilityAddTraits(selection == icon ? .isSelected : [])
            }
        }
    }
}

#Preview {
    AddExpenseSheet(viewModel: ExpensesViewModel())
}
