import SwiftUI
import DesignSystem
import SharedUI
import Utilities

struct SalaryEntryStep: View {
    @Binding var income: Decimal
    let lastMonthIncome: Decimal
    let currency: Currency
    let canContinue: Bool
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            headerSection
            amountInput
            lastMonthHint

            Spacer()
            Spacer()

            continueButton
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .contentShape(Rectangle())
        .onTapGesture {
            KeyboardHelper.dismiss()
        }
    }
}

// MARK: - Subviews

private extension SalaryEntryStep {
    var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "banknote.fill")
                .iconXl()
                .foregroundStyle(DiamerisColors.accentPrimary)
                .accessibilityHidden(true)

            Text("How much did you receive?".localized)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
        }
    }

    var amountInput: some View {
        CurrencyAmountField(
            amount: $income,
            currency: .constant(currency),
            showCurrencyPicker: false
        )
    }

    @ViewBuilder
    var lastMonthHint: some View {
        if lastMonthIncome > 0 {
            Text(lastMonthText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    var lastMonthText: String {
        let formatted = AmountFormatter.formatForDisplay(lastMonthIncome, currency: currency.rawValue)
        return String(
            localized: "Last month: \(formatted)",
            bundle: .module
        )
    }

    var continueButton: some View {
        Button {
            onContinue()
        } label: {
            Text("Continue".localized)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.glassProminent)
        .tint(DiamerisColors.accentPrimaryFill)
        .disabled(!canContinue)
    }
}

#Preview {
    SalaryEntryStep(
        income: .constant(14303),
        lastMonthIncome: 14303,
        currency: .ron,
        canContinue: true,
        onContinue: {}
    )
}
