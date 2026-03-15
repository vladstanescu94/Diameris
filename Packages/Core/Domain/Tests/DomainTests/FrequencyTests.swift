import Foundation
import Testing
@testable import Domain

/// Tests for Frequency enum - validates multiplier calculations
/// and conversion properties.
@Suite("Frequency Tests")
struct FrequencyTests {

    // MARK: - Monthly Multiplier

    @Suite("Monthly Multiplier")
    struct MonthlyMultiplierTests {

        @Test("Monthly frequency has multiplier of 1")
        func monthlyMultiplierIsOne() {
            #expect(Frequency.monthly.monthlyMultiplier == 1)
        }

        @Test("Annual frequency has multiplier of 1/12")
        func annualMultiplierIsOneTwelfth() {
            let expected = Decimal(1) / 12
            #expect(Frequency.annual.monthlyMultiplier == expected)
        }
    }

    // MARK: - Annual Multiplier

    @Suite("Annual Multiplier")
    struct AnnualMultiplierTests {

        @Test("Monthly frequency has annual multiplier of 12")
        func monthlyAnnualMultiplierIs12() {
            #expect(Frequency.monthly.annualMultiplier == 12)
        }

        @Test("Annual frequency has annual multiplier of 1")
        func annualAnnualMultiplierIsOne() {
            #expect(Frequency.annual.annualMultiplier == 1)
        }
    }

    // MARK: - Amount Conversions

    @Suite("Amount Conversions")
    struct AmountConversionTests {

        @Test("Monthly amount stays same for monthly frequency")
        func monthlyAmountStaysSame() {
            let amount: Decimal = 1000
            let result = amount * Frequency.monthly.monthlyMultiplier
            #expect(result == 1000)
        }

        @Test("Annual amount converts to monthly correctly")
        func annualToMonthlyConversion() {
            let annualAmount: Decimal = 1200
            let monthlyResult = annualAmount * Frequency.annual.monthlyMultiplier
            // Using approximate comparison due to Decimal division precision
            #expect(abs(monthlyResult - 100) < Decimal(string: "0.01")!)
        }

        @Test("Monthly amount converts to annual correctly")
        func monthlyToAnnualConversion() {
            let monthlyAmount: Decimal = 100
            let annualResult = monthlyAmount * Frequency.monthly.annualMultiplier
            #expect(annualResult == 1200)
        }

        @Test("Annual amount stays same for annual frequency")
        func annualAmountStaysSame() {
            let amount: Decimal = 1200
            let result = amount * Frequency.annual.annualMultiplier
            #expect(result == 1200)
        }
    }

    // MARK: - Codable Conformance

    @Suite("Codable Conformance")
    struct CodableTests {

        @Test("Monthly encodes and decodes correctly")
        func monthlyRoundTrip() throws {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()

            let data = try encoder.encode(Frequency.monthly)
            let decoded = try decoder.decode(Frequency.self, from: data)

            #expect(decoded == .monthly)
        }

        @Test("Annual encodes and decodes correctly")
        func annualRoundTrip() throws {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()

            let data = try encoder.encode(Frequency.annual)
            let decoded = try decoder.decode(Frequency.self, from: data)

            #expect(decoded == .annual)
        }

        @Test("Raw value encoding", arguments: Frequency.allCases)
        func rawValueEncoding(frequency: Frequency) throws {
            let encoder = JSONEncoder()
            let data = try encoder.encode(frequency)
            let string = String(data: data, encoding: .utf8)!

            #expect(string.contains(frequency.rawValue))
        }
    }

    // MARK: - Icon Property

    @Suite("Icon Property")
    struct IconTests {

        @Test("Monthly has calendar icon")
        func monthlyIcon() {
            #expect(Frequency.monthly.icon == "calendar")
        }

        @Test("Annual has calendar badge clock icon")
        func annualIcon() {
            #expect(Frequency.annual.icon == "calendar.badge.clock")
        }

        @Test("All frequencies have non-empty icons", arguments: Frequency.allCases)
        func allHaveIcons(frequency: Frequency) {
            #expect(frequency.icon.isEmpty == false)
        }
    }

    // MARK: - CaseIterable

    @Suite("CaseIterable")
    struct CaseIterableTests {

        @Test("Has exactly 2 cases")
        func hasTwoCases() {
            #expect(Frequency.allCases.count == 2)
        }

        @Test("Contains monthly")
        func containsMonthly() {
            #expect(Frequency.allCases.contains(.monthly))
        }

        @Test("Contains annual")
        func containsAnnual() {
            #expect(Frequency.allCases.contains(.annual))
        }
    }
}
