import Foundation

/// Serialises all access to the single JSON document that is this app's database.
///
/// An `actor` because concurrent requests would otherwise interleave read-modify-write cycles
/// and lose updates. Writes are **atomic**: encode to a temp file in the same directory, then
/// `FileManager.replaceItem`, so a crash mid-write can never leave a half-written store behind —
/// you either get the old document or the new one.
public actor JSONStore {
    private let fileURL: URL
    private var cached: StoreDocument?

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    /// Default location: `~/.diameris/web-store.json`.
    public static var defaultURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".diameris", isDirectory: true)
            .appendingPathComponent("web-store.json", isDirectory: false)
    }

    public init(fileURL: URL = JSONStore.defaultURL) {
        self.fileURL = fileURL
    }

    public var location: URL { fileURL }

    // MARK: - Reading

    /// Loads the document, seeding it on first launch.
    ///
    /// A document that fails to decode (hand-edited, or written by an incompatible build) is
    /// moved aside to `web-store.corrupt-<n>.json` rather than deleted, and a fresh seeded
    /// document takes its place. Losing a local dev store silently would be worse than loudly.
    public func load() throws -> StoreDocument {
        if let cached { return cached }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            let seeded = StoreDocument.seeded()
            try persist(seeded)
            cached = seeded
            return seeded
        }

        let data = try Data(contentsOf: fileURL)
        do {
            var document = try decoder.decode(StoreDocument.self, from: data)
            if document.schemaVersion != StoreDocument.currentSchemaVersion {
                document = try migrate(document)
                try persist(document)
            }
            cached = document
            return document
        } catch {
            try quarantineCorruptStore()
            let seeded = StoreDocument.seeded()
            try persist(seeded)
            cached = seeded
            return seeded
        }
    }

    // MARK: - Writing

    /// Read-modify-write under the actor's isolation, so no two mutations can interleave.
    /// Returns the mutated document.
    @discardableResult
    public func mutate<T: Sendable>(
        _ body: (inout StoreDocument) throws -> T
    ) throws -> (document: StoreDocument, result: T) {
        var document = try load()
        let result = try body(&document)
        document.schemaVersion = StoreDocument.currentSchemaVersion
        try persist(document)
        cached = document
        return (document, result)
    }

    /// Wipes the store and re-seeds it — the Developer Tools "reset" parity hook.
    @discardableResult
    public func reset() throws -> StoreDocument {
        let seeded = StoreDocument.seeded()
        try persist(seeded)
        cached = seeded
        return seeded
    }

    // MARK: - Private

    private func persist(_ document: StoreDocument) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let data = try encoder.encode(document)

        // Temp file must live in the same directory so replaceItem stays a same-volume rename.
        let tempURL = directory.appendingPathComponent(
            ".web-store.\(UUID().uuidString).tmp",
            isDirectory: false
        )
        try data.write(to: tempURL, options: .atomic)

        if FileManager.default.fileExists(atPath: fileURL.path) {
            _ = try FileManager.default.replaceItemAt(fileURL, withItemAt: tempURL)
        } else {
            try FileManager.default.moveItem(at: tempURL, to: fileURL)
        }
    }

    private func quarantineCorruptStore() throws {
        let directory = fileURL.deletingLastPathComponent()
        var index = 0
        var target: URL
        repeat {
            target = directory.appendingPathComponent("web-store.corrupt-\(index).json")
            index += 1
        } while FileManager.default.fileExists(atPath: target.path) && index < 100
        try? FileManager.default.moveItem(at: fileURL, to: target)
    }

    /// Only schema 1 exists. This is the seam a future version writes its migration into;
    /// an unknown *newer* version is left untouched rather than guessed at.
    private func migrate(_ document: StoreDocument) throws -> StoreDocument {
        var migrated = document
        migrated.schemaVersion = StoreDocument.currentSchemaVersion
        return migrated
    }
}
