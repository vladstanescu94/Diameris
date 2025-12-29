import SwiftUI
import Domain
import DesignSystem
import Utilities

/// Picker for selecting expense subcategory
public struct SubcategoryPicker: View {
    @Binding var selection: UUID?
    let subcategories: [Subcategory]
    var showNone: Bool = true

    public init(
        selection: Binding<UUID?>,
        subcategories: [Subcategory],
        showNone: Bool = true
    ) {
        self._selection = selection
        self.subcategories = subcategories
        self.showNone = showNone
    }

    public var body: some View {
        Picker("Subcategory".localized, selection: $selection) {
            if showNone {
                Text("None".localized)
                    .tag(nil as UUID?)
            }

            ForEach(subcategories) { subcategory in
                Text(subcategory.name)
                    .tag(subcategory.id as UUID?)
            }
        }
        .onChange(of: selection) { _, _ in
            HapticManager.selectionChanged()
        }
    }
}

#Preview {
    @Previewable @State var selectedSubcategory: UUID? = nil

    Form {
        SubcategoryPicker(
            selection: $selectedSubcategory,
            subcategories: Subcategory.defaults(for: ExpenseCategory.autoTransport.id)
        )
    }
}
