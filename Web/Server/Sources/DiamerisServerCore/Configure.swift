import Foundation
import NIOCore
import Vapor

public enum ServerConfiguration {
    /// Local-only by design: this app has no auth and no multi-user story, so binding anything
    /// but loopback would expose an unauthenticated store to the network.
    public static let hostname = "127.0.0.1"
    public static let defaultPort = 8080

    /// `DIAMERIS_PORT`, else 8080.
    ///
    /// Exists so the Verify harness can run its own instance (8081) with its own store while
    /// someone else drives the real one on 8080 — otherwise the harness's `POST /api/reset` wipes
    /// the store another agent is reading mid-session, and browser verification is racy for
    /// everyone (R29).
    public static var port: Int {
        ProcessInfo.processInfo.environment["DIAMERIS_PORT"].flatMap(Int.init) ?? defaultPort
    }

    /// `DIAMERIS_STORE`, else `~/.diameris/web-store.json`. A relative path resolves against the
    /// current directory. Point it at a temp file for a disposable instance.
    public static var storeURL: URL {
        guard let raw = ProcessInfo.processInfo.environment["DIAMERIS_STORE"], !raw.isEmpty else {
            return JSONStore.defaultURL
        }
        return URL(fileURLWithPath: (raw as NSString).expandingTildeInPath).standardizedFileURL
    }
}

/// Wires up the store, the routes and the static SPA.
public func configure(
    _ app: Application,
    storeURL: URL = ServerConfiguration.storeURL,
    port: Int = ServerConfiguration.port
) throws {
    LocalePin.apply()
    if !LocalePin.isEffective {
        app.logger.warning(
            """
            Locale pin did not take effect (Locale.current = \(Locale.current.identifier), \
            expected \(LocalePin.identifier)). Money formatting may vary by machine.
            """
        )
    }

    app.http.server.configuration.hostname = ServerConfiguration.hostname
    app.http.server.configuration.port = port

    // Pretty-print and sort keys so a curl'd response is readable and diffable — this is a local
    // dev tool, and the Verify harness compares payloads.
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    encoder.dateEncodingStrategy = .iso8601
    ContentConfiguration.global.use(encoder: encoder, for: .json)

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    ContentConfiguration.global.use(decoder: decoder, for: .json)

    app.logger.info("Store: \(storeURL.path)")
    let context = AppContext(store: JSONStore(fileURL: storeURL))
    try registerRoutes(app, context: context)

    // Serve the built client from the same origin, so there is no CORS to configure.
    let clientDist = clientDistDirectory()
    if let clientDist {
        app.middleware.use(
            FileMiddleware(publicDirectory: clientDist.path + "/", defaultFile: "index.html")
        )
        app.logger.info("Serving client from \(clientDist.path)")
    } else {
        app.logger.warning("No client build found — API only. Run `npm run build` in Web/Client.")
    }

    // SPA fallback: any unmatched GET that is not an API call renders index.html, so deep links
    // like /dashboard work on a client-side router.
    app.get(.catchall) { request -> Response in
        guard let clientDist,
              !request.url.path.hasPrefix("/api"),
              request.headers.accept.contains(where: { $0.mediaType == .html })
        else {
            throw Abort(.notFound)
        }
        let index = clientDist.appendingPathComponent("index.html")
        guard FileManager.default.fileExists(atPath: index.path) else {
            throw Abort(.notFound)
        }
        return try await request.fileio.asyncStreamFile(at: index.path)
    }
}

/// `Web/Client/dist`, resolved relative to this source file so it works from any cwd.
private func clientDistDirectory() -> URL? {
    var candidates: [URL] = []

    // …/Web/Server/Sources/DiamerisServerCore/Configure.swift → …/Web/Client/dist
    let sourceFile = URL(fileURLWithPath: #filePath)
    candidates.append(
        sourceFile
            .deletingLastPathComponent()  // DiamerisServerCore
            .deletingLastPathComponent()  // Sources
            .deletingLastPathComponent()  // Server
            .deletingLastPathComponent()  // Web
            .appendingPathComponent("Client/dist", isDirectory: true)
    )

    let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    candidates.append(cwd.appendingPathComponent("../Client/dist", isDirectory: true))
    candidates.append(cwd.appendingPathComponent("Web/Client/dist", isDirectory: true))

    return candidates.first { FileManager.default.fileExists(atPath: $0.path) }?.standardizedFileURL
}
