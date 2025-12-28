import Foundation
import Testing
@testable import Onboarding

/// Tests for AccountType enum - validates behavioral properties,
/// uniqueness rules, and display properties.
@Suite("AccountType Tests")
struct AccountTypeTests {

    // MARK: - Behavioral Properties

    @Suite("Behavioral Properties")
    struct BehavioralProperties {

        @Test("Primary has behavior")
        func primaryHasBehavior() {
            #expect(AccountType.primary.hasBehavior == true)
        }

        @Test("Emergency has behavior")
        func emergencyHasBehavior() {
            #expect(AccountType.emergency.hasBehavior == true)
        }

        @Test("Savings has behavior")
        func savingsHasBehavior() {
            #expect(AccountType.savings.hasBehavior == true)
        }

        @Test("Personal has behavior")
        func personalHasBehavior() {
            #expect(AccountType.personal.hasBehavior == true)
        }

        @Test("Joint does not have behavior")
        func jointNoBehavior() {
            #expect(AccountType.joint.hasBehavior == false)
        }

        @Test("Other does not have behavior")
        func otherNoBehavior() {
            #expect(AccountType.other.hasBehavior == false)
        }

        @Test("Types with behavior",
              arguments: [AccountType.primary, .emergency, .savings, .personal])
        func typesWithBehavior(type: AccountType) {
            #expect(type.hasBehavior == true)
        }

        @Test("Types without behavior",
              arguments: [AccountType.joint, .other])
        func typesWithoutBehavior(type: AccountType) {
            #expect(type.hasBehavior == false)
        }
    }

    // MARK: - Uniqueness Rules

    @Suite("Uniqueness Rules")
    struct UniquenessRules {

        @Test("Only emergency is unique")
        func onlyEmergencyIsUnique() {
            #expect(AccountType.emergency.isUnique == true)
        }

        @Test("Non-emergency types are not unique",
              arguments: [AccountType.primary, .savings, .personal, .joint, .other])
        func nonEmergencyNotUnique(type: AccountType) {
            #expect(type.isUnique == false)
        }
    }

    // MARK: - Display Properties

    @Suite("Display Properties")
    struct DisplayProperties {

        @Test("All types have display names")
        func allTypesHaveDisplayNames() {
            for type in AccountType.allCases {
                #expect(!type.displayName.isEmpty, "Type \(type) should have a display name")
            }
        }

        @Test("All types have icons")
        func allTypesHaveIcons() {
            for type in AccountType.allCases {
                #expect(!type.icon.isEmpty, "Type \(type) should have an icon")
            }
        }

        @Test("All types have descriptions")
        func allTypesHaveDescriptions() {
            for type in AccountType.allCases {
                #expect(!type.description.isEmpty, "Type \(type) should have a description")
            }
        }

        @Test("Icons are SF Symbol names")
        func iconsAreSFSymbols() {
            let expectedPatterns = [
                AccountType.primary: "building.columns.fill",
                AccountType.emergency: "shield.fill",
                AccountType.savings: "banknote.fill",
                AccountType.personal: "person.fill",
                AccountType.joint: "person.2.fill",
                AccountType.other: "creditcard.fill"
            ]

            for (type, expectedIcon) in expectedPatterns {
                #expect(type.icon == expectedIcon)
            }
        }
    }

    // MARK: - Identifiable

    @Suite("Identifiable")
    struct Identifiable {

        @Test("ID equals raw value")
        func idEqualsRawValue() {
            for type in AccountType.allCases {
                #expect(type.id == type.rawValue)
            }
        }

        @Test("All IDs are unique")
        func allIDsUnique() {
            let ids = AccountType.allCases.map { $0.id }
            let uniqueIds = Set(ids)

            #expect(ids.count == uniqueIds.count)
        }
    }

    // MARK: - Raw Values

    @Suite("Raw Values")
    struct RawValues {

        @Test("Primary raw value")
        func primaryRawValue() {
            #expect(AccountType.primary.rawValue == "primary")
        }

        @Test("Emergency raw value")
        func emergencyRawValue() {
            #expect(AccountType.emergency.rawValue == "emergency")
        }

        @Test("Savings raw value")
        func savingsRawValue() {
            #expect(AccountType.savings.rawValue == "savings")
        }

        @Test("Personal raw value")
        func personalRawValue() {
            #expect(AccountType.personal.rawValue == "personal")
        }

        @Test("Joint raw value")
        func jointRawValue() {
            #expect(AccountType.joint.rawValue == "joint")
        }

        @Test("Other raw value")
        func otherRawValue() {
            #expect(AccountType.other.rawValue == "other")
        }

        @Test("Can create from raw value")
        func createFromRawValue() {
            #expect(AccountType(rawValue: "primary") == .primary)
            #expect(AccountType(rawValue: "emergency") == .emergency)
            #expect(AccountType(rawValue: "savings") == .savings)
            #expect(AccountType(rawValue: "invalid") == nil)
        }
    }

    // MARK: - CaseIterable

    @Suite("CaseIterable")
    struct CaseIterableTests {

        @Test("Has 6 cases")
        func hasSixCases() {
            #expect(AccountType.allCases.count == 6)
        }

        @Test("All cases included")
        func allCasesIncluded() {
            let cases = AccountType.allCases

            #expect(cases.contains(.primary))
            #expect(cases.contains(.emergency))
            #expect(cases.contains(.savings))
            #expect(cases.contains(.personal))
            #expect(cases.contains(.joint))
            #expect(cases.contains(.other))
        }
    }

    // MARK: - Codable

    @Suite("Codable")
    struct CodableTests {

        @Test("Encode and decode round-trip",
              arguments: AccountType.allCases)
        func encodeDecodeRoundTrip(type: AccountType) throws {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()

            let encoded = try encoder.encode(type)
            let decoded = try decoder.decode(AccountType.self, from: encoded)

            #expect(decoded == type)
        }

        @Test("Encodes to raw value string")
        func encodesToRawValue() throws {
            let encoder = JSONEncoder()
            let data = try encoder.encode(AccountType.emergency)
            let string = String(data: data, encoding: .utf8)

            #expect(string == "\"emergency\"")
        }
    }

    // MARK: - Sendable

    @Suite("Sendable")
    struct SendableTests {

        @Test("Can be used across actor boundaries")
        func canCrossActorBoundaries() async {
            let type = AccountType.emergency

            // This should compile without warnings due to Sendable conformance
            let result = await Task.detached {
                return type.hasBehavior
            }.value

            #expect(result == true)
        }
    }
}
