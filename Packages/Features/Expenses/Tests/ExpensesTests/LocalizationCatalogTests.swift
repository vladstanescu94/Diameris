import Foundation
import Testing

/// `"…".localized` looks its receiver up as a catalog key, so an interpolated literal is
/// looked up after interpolation and never matches — Romanian users see English.
struct LocalizationCatalogTests {
    private static let packageRoot = URL(filePath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    @Test func `Every localized literal is a catalog key with a Romanian translation`() throws {
        let sources = Self.packageRoot.appending(path: "Sources/Expenses")
        let catalog = try Data(contentsOf: sources.appending(path: "Resources/Localizable.xcstrings"))
        let strings = try #require(
            (try JSONSerialization.jsonObject(with: catalog) as? [String: Any])?["strings"] as? [String: Any]
        )
        let romanianKeys = Set(strings.compactMap { key, entry in
            let localizations = (entry as? [String: Any])?["localizations"] as? [String: Any]
            return localizations?["ro"] == nil ? nil : key
        })

        let files = try #require(FileManager.default.enumerator(at: sources, includingPropertiesForKeys: nil))
        var keys: Set<String> = []
        for case let file as URL in files where file.pathExtension == "swift" {
            let source = try String(contentsOf: file, encoding: .utf8)
            keys.formUnion(source.matches(of: /"((?:[^"\\]|\\.)*)"\.localized\b/).map { String($0.1) })
        }

        #expect(!keys.isEmpty)
        #expect(keys.subtracting(romanianKeys).sorted() == [])
    }
}
