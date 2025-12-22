import SwiftUI
import DesignSystem

public struct OnboardingTextField: View {
    let title: String
    @Binding var text: String
    let prompt: String
    var keyboardType: UIKeyboardType = .default

    public init(
        _ title: String,
        text: Binding<String>,
        prompt: String,
        keyboardType: UIKeyboardType = .default
    ) {
        self.title = title
        self._text = text
        self.prompt = prompt
        self.keyboardType = keyboardType
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if !title.isEmpty {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            TextField(prompt, text: $text)
                .font(.title3)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(keyboardType == .default ? .words : .never)
                .padding(Spacing.md)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: CornerRadius.medium))
        }
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        OnboardingTextField(
            "Your name",
            text: .constant(""),
            prompt: "Enter your name"
        )

        OnboardingTextField(
            "",
            text: .constant("John"),
            prompt: "Enter your name"
        )
    }
    .padding()
}
