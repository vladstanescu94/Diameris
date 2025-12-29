import SwiftUI
import Domain
import DesignSystem
import Utilities

/// Picker for selecting expense category
public struct CategoryPicker: View {
    @Binding var selection: UUID?
    let categories: [ExpenseCategory]
    var showNone: Bool = true

    public init(
        selection: Binding<UUID?>,
        categories: [ExpenseCategory],
        showNone: Bool = true
    ) {
        self._selection = selection
        self.categories = categories
        self.showNone = showNone
    }

    public var body: some View {
        Picker("Category".localized, selection: $selection) {
            if showNone {
                Text("None".localized)
                    .tag(nil as UUID?)
            }

            ForEach(categories) { category in
                Label(category.name, systemImage: category.icon)
                    .tag(category.id as UUID?)
            }
        }
        .onChange(of: selection) { _, _ in
            HapticManager.selectionChanged()
        }
    }
}

#Preview {
    @Previewable @State var selectedCategory: UUID? = nil

    Form {
        CategoryPicker(
            selection: $selectedCategory,
            categories: ExpenseCategory.defaults
        )
    }
}
