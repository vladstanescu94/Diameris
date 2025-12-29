import SwiftUI
import Domain
import DesignSystem
import Utilities

/// Picker for selecting expense frequency (monthly/annual)
public struct FrequencyPicker: View {
    @Binding var selection: Frequency

    public init(selection: Binding<Frequency>) {
        self._selection = selection
    }

    public var body: some View {
        Picker("Frequency".localized, selection: $selection) {
            ForEach(Frequency.allCases, id: \.self) { frequency in
                Label(frequency.displayName, systemImage: frequency.icon)
                    .tag(frequency)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: selection) { _, _ in
            HapticManager.selectionChanged()
        }
    }
}

extension Frequency {
    var displayName: String {
        switch self {
        case .monthly:
            return "Monthly".localized
        case .annual:
            return "Annual".localized
        }
    }
}

#Preview {
    @Previewable @State var frequency: Frequency = .monthly

    VStack(spacing: Spacing.lg) {
        FrequencyPicker(selection: $frequency)
        Text("Selected: \(frequency.displayName)")
    }
    .padding()
}
