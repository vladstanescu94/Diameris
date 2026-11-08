import SwiftUI
import Domain

struct PercentageSliderRow: View {
    let title: String
    @Binding var value: Double
    let tint: Color

    private static let step = 0.01
    private static let format = FloatingPointFormatStyle<Double>.Percent.percent.precision(.fractionLength(0))

    var body: some View {
        VStack(alignment: .leading) {
            LabeledContent(title) {
                Text(value, format: Self.format)
                    .monospacedDigit()
            }
            .accessibilityHidden(true)

            Slider(
                value: $value,
                in: SavingsAllocationEntry.minimumPercentage...SavingsAllocationEntry.maximumPercentage,
                step: Self.step
            ) {
                Text(title)
            }
            .tint(tint)
            // Without this VoiceOver reads the position within the range, not the rate itself.
            .accessibilityValue(Text(value, format: Self.format))
        }
    }
}
