import Testing
@testable import Onboarding

@Suite("OnboardingViewModel Tests")
struct OnboardingViewModelTests {
    @Test("Initial state is name step")
    func initialStateIsNameStep() {
        let viewModel = OnboardingViewModel()
        #expect(viewModel.currentStep == .name)
    }

    @Test("Cannot advance with empty name")
    func cannotAdvanceWithEmptyName() {
        let viewModel = OnboardingViewModel()
        viewModel.name = ""
        #expect(viewModel.canAdvance == false)
    }

    @Test("Cannot advance with whitespace-only name")
    func cannotAdvanceWithWhitespaceName() {
        let viewModel = OnboardingViewModel()
        viewModel.name = "   "
        #expect(viewModel.canAdvance == false)
    }

    @Test("Can advance with valid name")
    func canAdvanceWithValidName() {
        let viewModel = OnboardingViewModel()
        viewModel.name = "Vlad"
        #expect(viewModel.canAdvance == true)
    }

    @Test("Advance moves to income step")
    func advanceMovesToIncomeStep() {
        let viewModel = OnboardingViewModel()
        viewModel.name = "Vlad"
        viewModel.advance()
        #expect(viewModel.currentStep == .income)
    }

    @Test("Cannot advance income with zero amount")
    func cannotAdvanceIncomeWithZero() {
        let viewModel = OnboardingViewModel()
        viewModel.name = "Vlad"
        viewModel.advance()
        viewModel.monthlyIncome = 0
        #expect(viewModel.canAdvance == false)
    }

    @Test("Can advance income with positive amount")
    func canAdvanceIncomeWithPositiveAmount() {
        let viewModel = OnboardingViewModel()
        viewModel.name = "Vlad"
        viewModel.advance()
        viewModel.monthlyIncome = 14303
        #expect(viewModel.canAdvance == true)
    }

    @Test("Currency detects from locale")
    func currencyDetectsFromLocale() {
        let currency = Currency.fromLocale()
        #expect(Currency.allCases.contains(currency))
    }

    @Test("Trimmed name removes whitespace")
    func trimmedNameRemovesWhitespace() {
        let viewModel = OnboardingViewModel()
        viewModel.name = "  Vlad  "
        #expect(viewModel.trimmedName == "Vlad")
    }
}
