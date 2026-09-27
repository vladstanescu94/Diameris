import SwiftUI
import Testing
@testable import SharedUI

struct ConfettiParticleTests {

    /// The closed form must match 60 fps "position += velocity; velocity.dy += gravity" stepping.
    @Test(arguments: [0, 1, 30, 90])
    func `Closed-form motion matches per-frame stepping`(frames: Int) {
        let gravity: CGFloat = 0.3
        let start = ConfettiParticle(
            position: CGPoint(x: 100, y: -20),
            color: .pink,
            rotation: 45,
            scale: 1,
            velocity: CGVector(dx: -3, dy: 5),
            angularVelocity: 7
        )

        var stepped = start
        for _ in 0..<frames {
            stepped.position.x += stepped.velocity.dx
            stepped.position.y += stepped.velocity.dy
            stepped.velocity.dy += gravity
            stepped.rotation += stepped.angularVelocity
        }

        let position = start.position(afterFrames: Double(frames), gravity: gravity)
        #expect(abs(position.x - stepped.position.x) < 0.001)
        #expect(abs(position.y - stepped.position.y) < 0.001)
        #expect(start.rotation(afterFrames: Double(frames)) == stepped.rotation)
    }
}
