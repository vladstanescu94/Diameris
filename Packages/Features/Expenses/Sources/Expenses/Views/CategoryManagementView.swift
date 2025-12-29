import SwiftUI
import Domain
import DesignSystem
import Utilities

/// View for managing expense categories
public struct CategoryManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: ExpensesViewModel

    @State private var showAddCategory = false
    @State private var selectedCategory: ExpenseCategory?

    public init(viewModel: ExpensesViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            List {
                // Default categories section
                Section {
                    ForEach(ExpenseCategory.defaults) { category in
                        CategoryRow(
                            category: category,
                            isDefault: true,
                            subcategoryCount: Subcategory.defaults(for: category.id).count
                        )
                        .onTapGesture {
                            HapticManager.lightTap()
                            selectedCategory = category
                        }
                    }
                } header: {
                    Text("Default Categories".localized)
                } footer: {
                    Text("Default categories cannot be deleted.".localized)
                }

                // Custom categories section
                if !viewModel.customCategories.isEmpty {
                    Section {
                        ForEach(viewModel.customCategories) { category in
                            CategoryRow(
                                category: category,
                                isDefault: false,
                                subcategoryCount: (viewModel.customSubcategories[category.id]?.count ?? 0) +
                                    Subcategory.defaults(for: category.id).count
                            )
                            .onTapGesture {
                                HapticManager.lightTap()
                                selectedCategory = category
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    HapticManager.warning()
                                    Task {
                                        await viewModel.onDeleteCategory?(category.id)
                                    }
                                } label: {
                                    Label("Delete".localized, systemImage: "trash")
                                }
                            }
                        }
                    } header: {
                        Text("Custom Categories".localized)
                    }
                }
            }
            .navigationTitle("Categories".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done".localized) {
                        HapticManager.lightTap()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        HapticManager.lightTap()
                        showAddCategory = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddCategory) {
                AddCategorySheet(viewModel: viewModel)
            }
            .sheet(item: $selectedCategory) { category in
                SubcategoryManagementView(
                    viewModel: viewModel,
                    category: category
                )
            }
        }
    }
}

/// Row displaying a category in the list
struct CategoryRow: View {
    let category: ExpenseCategory
    let isDefault: Bool
    let subcategoryCount: Int

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: category.icon)
                .font(.title2)
                .foregroundStyle(Color(hex: category.colorHex) ?? .gray)
                .frame(width: IconSize.lg, height: IconSize.lg)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(category.name)
                    .font(.body)

                Text("\(subcategoryCount) " + "subcategories".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isDefault {
                Text("Default".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(.secondary.opacity(0.2))
                    .clipShape(Capsule())
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, Spacing.xs)
        .contentShape(Rectangle())
    }
}

/// Sheet for adding a new category
struct AddCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: ExpensesViewModel

    @State private var name = ""
    @State private var selectedIcon = "star.fill"
    @State private var selectedColor = "#3B82F6"

    private let colors = [
        "#3B82F6", // Blue
        "#8B5CF6", // Purple
        "#F59E0B", // Amber
        "#10B981", // Emerald
        "#EC4899", // Pink
        "#EF4444", // Red
        "#22C55E", // Green
        "#06B6D4", // Cyan
        "#F97316", // Orange
        "#6366F1"  // Indigo
    ]

    private let icons = [
        "star.fill", "heart.fill", "bolt.fill", "leaf.fill",
        "gift.fill", "tag.fill", "bookmark.fill", "flag.fill",
        "bell.fill", "clock.fill", "calendar", "folder.fill"
    ]

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name".localized, text: $name)
                } header: {
                    Text("Category Name".localized)
                }

                Section {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: Spacing.sm) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                HapticManager.lightTap()
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(selectedIcon == icon ? Color.accentColor.opacity(0.2) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("Icon".localized)
                }

                Section {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: Spacing.sm) {
                        ForEach(colors, id: \.self) { color in
                            Button {
                                HapticManager.lightTap()
                                selectedColor = color
                            } label: {
                                Circle()
                                    .fill(Color(hex: color) ?? .gray)
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        if selectedColor == color {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("Color".localized)
                }

                // Preview
                Section {
                    HStack(spacing: Spacing.md) {
                        Image(systemName: selectedIcon)
                            .font(.title2)
                            .foregroundStyle(Color(hex: selectedColor) ?? .gray)
                            .frame(width: IconSize.lg, height: IconSize.lg)

                        Text(name.isEmpty ? "Category Name".localized : name)
                            .font(.body)
                    }
                } header: {
                    Text("Preview".localized)
                }
            }
            .navigationTitle("New Category".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) {
                        HapticManager.lightTap()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add".localized) {
                        HapticManager.success()
                        Task {
                            await viewModel.onAddCategory?(name, selectedIcon, selectedColor)
                            dismiss()
                        }
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}

/// View for managing subcategories within a category
struct SubcategoryManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: ExpensesViewModel
    let category: ExpenseCategory

    @State private var showAddSubcategory = false
    @State private var newSubcategoryName = ""

    private var defaultSubcategories: [Subcategory] {
        Subcategory.defaults(for: category.id)
    }

    private var customSubcategories: [Subcategory] {
        viewModel.customSubcategories[category.id] ?? []
    }

    var body: some View {
        NavigationStack {
            List {
                if !defaultSubcategories.isEmpty {
                    Section {
                        ForEach(defaultSubcategories) { subcategory in
                            SubcategoryRow(subcategory: subcategory, isDefault: true)
                        }
                    } header: {
                        Text("Default Subcategories".localized)
                    }
                }

                if !customSubcategories.isEmpty {
                    Section {
                        ForEach(customSubcategories) { subcategory in
                            SubcategoryRow(subcategory: subcategory, isDefault: false)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        HapticManager.warning()
                                        Task {
                                            await viewModel.onDeleteSubcategory?(subcategory.id)
                                        }
                                    } label: {
                                        Label("Delete".localized, systemImage: "trash")
                                    }
                                }
                        }
                    } header: {
                        Text("Custom Subcategories".localized)
                    }
                }

                // Add new subcategory inline
                Section {
                    HStack {
                        TextField("New Subcategory".localized, text: $newSubcategoryName)

                        Button {
                            HapticManager.success()
                            Task {
                                await viewModel.onAddSubcategory?(newSubcategoryName, category.id)
                                newSubcategoryName = ""
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                        .disabled(newSubcategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                } header: {
                    Text("Add Subcategory".localized)
                }
            }
            .navigationTitle(category.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done".localized) {
                        HapticManager.lightTap()
                        dismiss()
                    }
                }
            }
        }
    }
}

/// Row displaying a subcategory
struct SubcategoryRow: View {
    let subcategory: Subcategory
    let isDefault: Bool

    var body: some View {
        HStack {
            Text(subcategory.name)
                .font(.body)

            Spacer()

            if isDefault {
                Text("Default".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, Spacing.xxs)
    }
}

#Preview {
    CategoryManagementView(viewModel: ExpensesViewModel())
}
