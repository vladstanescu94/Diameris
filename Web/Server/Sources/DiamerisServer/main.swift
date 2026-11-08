import DiamerisServerCore
import Vapor

@main
struct Entrypoint {
    static func main() async throws {
        // Before anything else touches Locale.current — money formatting must not depend on
        // which laptop this runs on (R7).
        LocalePin.apply()

        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)

        let app = try await Application.make(env)
        do {
            try configure(app)
            app.logger.info(
                "Diameris web server on http://\(ServerConfiguration.hostname):\(ServerConfiguration.port)"
            )
            try await app.execute()
        } catch {
            // A port collision is by far the most common startup failure, and Vapor's default
            // report is a Swift fatal-error trace that reads like a crash. Name the culprit
            // instead — an operator can act on a pid, not on a stack trace.
            let description = String(describing: error)
            if description.contains("Address already in use") || description.contains("errno: 48") {
                app.logger.error(
                    """
                    Port \(ServerConfiguration.port) is already in use — another DiamerisServer is \
                    almost certainly running. Find it with \
                    `lsof -nP -iTCP:\(ServerConfiguration.port) -sTCP:LISTEN` and stop that pid, or \
                    set DIAMERIS_PORT to use a different port. Do NOT `pkill -f DiamerisServer`: \
                    that kills every instance, including other agents'.
                    """
                )
            } else {
                app.logger.report(error: error)
            }
            try? await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }
}
