import SwiftUI
import DesignSystem
import SharedUI
import Utilities

/// Step 1: Enter this month's salary.
struct SalaryEntryStep: View {
    @Binding var income: Decimal
    let lastMonthIncome: Decimal
    let currency: Currency
    let onContinue: () -> Void

    @State private var currencyBinding: Currency

    init(
        income: Binding<Decimal>,
        lastMonthIncome: Decimal,
        currency: Currency,
        onContinue: @escaping () -> Void
    ) {
        self._income = income
        self.lastMonthIncome = lastMonthIncome
        self.currency = currency
        self.onContinue = onContinue
        self._currencyBinding = State(initialValue: currency)
    }

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
            dismissKeyboard()
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Subviews

private extension SalaryEntryStep {
    var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "dollarsign.circle.fill")
                .iconXl()
                .foregroundStyle(DiamerisColors.accentPrimary)

            Text("How much did you receive?".localized)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
        }
    }

    var amountInput: some View {
        CurrencyAmountField(
            amount: $income,
            currency: $currencyBinding,
            showCurrencyPicker: false
        )
    }

    var lastMonthHint: some View {
        Group {
            if lastMonthIncome > 0 {
                Text(lastMonthText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
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
        .disabled(income <= 0)
    }
}

#Preview {
    SalaryEntryStep(
        income: .constant(14303),
        lastMonthIncome: 14303,
        currency: .ron,
        onContinue: {}
    )
}
