import SwiftUI
import DesignSystem
import Utilities

public struct ConfettiParticle: Identifiable {
    public let id = UUID()
    public var position: CGPoint
    public var color: Color
    public var rotation: Double
    public var scale: CGFloat
    public var velocity: CGVector
    public var angularVelocity: Double
}

extension ConfettiParticle {
    /// Where the particle is after `frames` ticks of 60 fps motion under constant `gravity`.
    ///
    /// Closed form of "each tick: position += velocity; velocity.dy += gravity", so the view can
    /// draw any frame straight from a `TimelineView` date instead of mutating state 60× a second.
    func position(afterFrames frames: Double, gravity: CGFloat) -> CGPoint {
        let ticks = CGFloat(frames)
        return CGPoint(
            x: position.x + velocity.dx * ticks,
            y: position.y + velocity.dy * ticks + gravity * ticks * (ticks - 1) / 2
        )
    }

    func rotation(afterFrames frames: Double) -> Double {
        rotation + angularVelocity * frames
    }
}

/// Confetti celebration effect. Draws nothing when Reduce Motion is on.
public struct ConfettiView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var particles: [ConfettiParticle] = []
    @State private var startDate: Date?

    private let particleCount = 50
    private let gravity: CGFloat = 0.3
    private let framesPerSecond: Double = 60
    private let maxScale: CGFloat = 1.2
    private let maxAngularVelocity: Double = 10
    private let minFallSpeed: CGFloat = 2
    private let fullTurn: Double = 360
    /// Long enough for every particle to fall off screen; the timeline stops after it.
    private let lifetime: Duration = .seconds(AnimationDuration.celebration * 3)

    let colors: [Color] = [
        DiamerisColors.accentPrimary,
        DiamerisColors.accentSecondary,
        .yellow,
        .orange,
        .pink,
        .cyan
    ]

    public init() {}

    public var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(paused: startDate == nil)) { context in
                let frames = elapsedFrames(at: context.date)
                ZStack {
                    ForEach(particles) { particle in
                        RoundedRectangle(cornerRadius: CornerRadius.xs)
                            .fill(particle.color)
                            .frame(
                                width: ComponentSize.confettiWidth * particle.scale,
                                height: ComponentSize.confettiHeight * particle.scale
                            )
                            .rotationEffect(.degrees(particle.rotation(afterFrames: frames)))
                            .position(particle.position(afterFrames: frames, gravity: gravity))
                    }
                }
            }
            .task {
                guard !reduceMotion else { return }
                createParticles(in: geometry.size)
                startDate = .now
                try? await Task.sleep(for: lifetime)
                startDate = nil
                particles = []
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func elapsedFrames(at date: Date) -> Double {
        guard let startDate else { return 0 }
        return max(0, date.timeIntervalSince(startDate)) * framesPerSecond
    }

    private func createParticles(in size: CGSize) {
        particles = (0..<particleCount).map { _ in
            ConfettiParticle(
                position: CGPoint(x: size.width / 2, y: -SlideOffset.standard),
                color: colors.randomElement() ?? .white,
                rotation: Double.random(in: 0...fullTurn),
                scale: CGFloat.random(in: Opacity.half...maxScale),
                velocity: CGVector(
                    dx: CGFloat.random(in: -ComponentSize.confettiWidth...ComponentSize.confettiWidth),
                    dy: CGFloat.random(in: minFallSpeed...ComponentSize.confettiWidth)
                ),
                angularVelocity: Double.random(in: -maxAngularVelocity...maxAngularVelocity)
            )
        }
    }
}

/// Ripple rings celebration effect. With Reduce Motion the rings fade in place instead of expanding.
public struct CelebrationRingsView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var ring1Scale: CGFloat = 0.1
    @State private var ring2Scale: CGFloat = 0.1
    @State private var ring3Scale: CGFloat = 0.1
    @State private var ring1Opacity: CGFloat = 1.0
    @State private var ring2Opacity: CGFloat = 1.0
    @State private var ring3Opacity: CGFloat = 1.0

    private let expandedScale: CGFloat = 2.5
    private let primaryLineWidth: CGFloat = 3
    private let secondaryLineWidth: CGFloat = 2
    private let tertiaryLineWidth: CGFloat = 1.5

    public init() {}

    public var body: some View {
        ZStack {
            Circle()
                .stroke(DiamerisColors.accentPrimary, lineWidth: primaryLineWidth)
                .scaleEffect(ring1Scale)
                .opacity(ring1Opacity)

            Circle()
                .stroke(DiamerisColors.accentSecondary, lineWidth: secondaryLineWidth)
                .scaleEffect(ring2Scale)
                .opacity(ring2Opacity)

            Circle()
                .stroke(DiamerisColors.accentPrimary.opacity(Opacity.half), lineWidth: tertiaryLineWidth)
                .scaleEffect(ring3Scale)
                .opacity(ring3Opacity)
        }
        .accessibilityHidden(true)
        .onAppear {
            animateRings()
        }
    }

    private func animateRings() {
        if reduceMotion {
            ring1Scale = 1
            ring2Scale = 1
            ring3Scale = 1
        }
        let targetScale = reduceMotion ? 1 : expandedScale

        withAnimation(.easeOut(duration: AnimationDuration.celebration)) {
            ring1Scale = targetScale
            ring1Opacity = 0
        }

        withAnimation(.easeOut(duration: AnimationDuration.celebration).delay(StaggerDelay.comfortable)) {
            ring2Scale = targetScale
            ring2Opacity = 0
        }

        withAnimation(.easeOut(duration: AnimationDuration.celebration).delay(StaggerDelay.initial)) {
            ring3Scale = targetScale
            ring3Opacity = 0
        }
    }
}

/// Success checkmark with bounce animation (a plain fade with Reduce Motion).
/// Decorative: the screen's title carries the meaning for VoiceOver.
public struct AnimatedCheckmark: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scale: CGFloat = 0.1
    @State private var rotation: Double = -30
    @State private var opacity: CGFloat = 0

    public init() {}

    public var body: some View {
        Image(systemName: "checkmark.circle.fill")
            .iconHero()
            .foregroundStyle(DiamerisColors.accentSecondary)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .accessibilityHidden(true)
            .onAppear {
                if reduceMotion {
                    scale = 1.0
                    rotation = 0
                }
                withAnimation(reduceMotion ? .easeOut(duration: AnimationDuration.standard) : SpringPreset.bouncy) {
                    scale = 1.0
                    rotation = 0
                    opacity = 1.0
                }
            }
    }
}

/// Combined celebration view for completion screens.
public struct CompletionCelebration: View {
    @State private var showConfetti = false
    @State private var showRings = false

    public init() {}

    public var body: some View {
        ZStack {
            if showRings {
                CelebrationRingsView()
                    .frame(
                        width: ComponentSize.celebrationRingSize,
                        height: ComponentSize.celebrationRingSize
                    )
            }

            if showConfetti {
                ConfettiView()
            }
        }
        .task {
            HapticManager.success()
            showRings = true
            try? await Task.sleep(for: .seconds(AnimationDuration.fast))
            showConfetti = true
        }
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.1)
        VStack {
            AnimatedCheckmark()
            CompletionCelebration()
        }
    }
}
