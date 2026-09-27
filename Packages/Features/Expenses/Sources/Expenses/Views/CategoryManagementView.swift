import SwiftUI
import Domain
import DesignSystem
import Utilities

public struct CategoryManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: ExpensesViewModel

    @State private var showAddCategory = false

    public init(viewModel: ExpensesViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(ExpenseCategory.defaults) { category in
                        CategoryRow(category: category, isDefault: true)
                    }
                } header: {
                    Text("Default Categories".localized)
                } footer: {
                    Text("Default categories cannot be deleted.".localized)
                }

                if !viewModel.customCategories.isEmpty {
                    Section {
                        ForEach(viewModel.customCategories) { category in
                            CategoryRow(category: category, isDefault: false)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        HapticManager.warning()
                                        Task {
                                            await viewModel.deleteCategory(category.id)
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
                    Button("New Category".localized, systemImage: "plus") {
                        HapticManager.lightTap()
                        showAddCategory = true
                    }
                }
            }
            .sheet(isPresented: $showAddCategory) {
                AddCategorySheet(viewModel: viewModel)
            }
        }
    }
}

struct CategoryRow: View {
    let category: ExpenseCategory
    let isDefault: Bool

    @ScaledMetric(relativeTo: .title2) private var iconSize = IconSize.lg

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: category.icon)
                .font(.title2)
                .foregroundStyle(Color(hex: category.colorHex) ?? .gray)
                .frame(width: iconSize, height: iconSize)
                .accessibilityHidden(true)

            Text(category.name)
                .font(.body)

            Spacer()

            if isDefault {
                Text("Default".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(.secondary.opacity(Opacity.light), in: .capsule)
            }
        }
        .padding(.vertical, Spacing.xs)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

struct AddCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: ExpensesViewModel
    var onCategoryCreated: ((UUID) -> Void)?

    @State private var name = ""
    @State private var selectedIcon = "star.fill"
    @State private var selectedColor = "#3B82F6"
    @State private var isSaving = false
    @ScaledMetric(relativeTo: .title2) private var iconSize = IconSize.lg

    /// Palette of (hex, spoken name) pairs; the name is what VoiceOver reads for each swatch.
    private let colors: [(hex: String, name: String)] = [
        ("#3B82F6", "Blue".localized),
        ("#8B5CF6", "Purple".localized),
        ("#F59E0B", "Amber".localized),
        ("#10B981", "Emerald".localized),
        ("#EC4899", "Pink".localized),
        ("#EF4444", "Red".localized),
        ("#22C55E", "Green".localized),
        ("#06B6D4", "Cyan".localized),
        ("#F97316", "Orange".localized),
        ("#6366F1", "Indigo".localized)
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
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: ComponentSize.minTouchTarget))], spacing: Spacing.sm) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                HapticManager.lightTap()
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .frame(width: ComponentSize.minTouchTarget, height: ComponentSize.minTouchTarget)
                                    .foregroundStyle(selectedIcon == icon ? Color.accentColor : Color.primary)
                                    .background(selectedIcon == icon ? Color.accentColor.opacity(Opacity.light) : Color.clear)
                                    .clipShape(.rect(cornerRadius: CornerRadius.small))
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(selectedIcon == icon ? .isSelected : [])
                        }
                    }
                } header: {
                    Text("Icon".localized)
                }

                Section {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: ComponentSize.minTouchTarget))], spacing: Spacing.sm) {
                        ForEach(colors, id: \.hex) { color in
                            Button {
                                HapticManager.lightTap()
                                selectedColor = color.hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: color.hex) ?? .gray)
                                    .frame(width: ComponentSize.buttonHeightSmall, height: ComponentSize.buttonHeightSmall)
                                    .overlay {
                                        if selectedColor == color.hex {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .frame(width: ComponentSize.minTouchTarget, height: ComponentSize.minTouchTarget)
                                    .contentShape(.circle)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(color.name)
                            .accessibilityAddTraits(selectedColor == color.hex ? .isSelected : [])
                        }
                    }
                } header: {
                    Text("Color".localized)
                }

                Section {
                    HStack(spacing: Spacing.md) {
                        Image(systemName: selectedIcon)
                            .font(.title2)
                            .foregroundStyle(Color(hex: selectedColor) ?? .gray)
                            .frame(width: iconSize, height: iconSize)

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
                        guard !isSaving else { return }
                        isSaving = true
                        HapticManager.success()
                        let categoryId = UUID()
                        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        Task {
                            await viewModel.addCategory(
                                id: categoryId,
                                name: trimmedName,
                                icon: selectedIcon,
                                colorHex: selectedColor
                            )
                            onCategoryCreated?(categoryId)
                            dismiss()
                        }
                    }
                    .disabled(!isValid || isSaving)
                }
            }
        }
    }
}

#Preview {
    CategoryManagementView(viewModel: ExpensesViewModel())
}
