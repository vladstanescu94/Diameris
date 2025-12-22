import SwiftUI
import DesignSystem

/// Particle for confetti animation
struct ConfettiParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var color: Color
    var rotation: Double
    var scale: CGFloat
    var velocity: CGVector
    var angularVelocity: Double
}

/// Confetti celebration effect
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var animationTimer: Timer?

    private let particleCount = 50
    private let gravity: CGFloat = 0.3

    let colors: [Color] = [
        DiamerisColors.accentPrimaryLight,
        DiamerisColors.accentSecondaryLight,
        .yellow,
        .orange,
        .pink,
        .cyan
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(particle.color)
                        .frame(
                            width: ComponentSize.confettiWidth * particle.scale,
                            height: ComponentSize.confettiHeight * particle.scale
                        )
                        .rotationEffect(.degrees(particle.rotation))
                        .position(particle.position)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                startAnimation()
            }
            .onDisappear {
                animationTimer?.invalidate()
            }
        }
        .allowsHitTesting(false)
    }

    private func createParticles(in size: CGSize) {
        particles = (0..<particleCount).map { _ in
            ConfettiParticle(
                position: CGPoint(x: size.width / 2, y: -SlideOffset.standard),
                color: colors.randomElement() ?? .white,
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: Opacity.half...1.2),
                velocity: CGVector(
                    dx: CGFloat.random(in: -ComponentSize.confettiWidth...ComponentSize.confettiWidth),
                    dy: CGFloat.random(in: 2...ComponentSize.confettiWidth)
                ),
                angularVelocity: Double.random(in: -10...10)
            )
        }
    }

    private func startAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
            updateParticles()
        }
    }

    private func updateParticles() {
        for index in particles.indices {
            particles[index].position.x += particles[index].velocity.dx
            particles[index].position.y += particles[index].velocity.dy
            particles[index].velocity.dy += gravity
            particles[index].rotation += particles[index].angularVelocity
        }
    }
}

/// Ripple rings celebration effect
struct CelebrationRingsView: View {
    @State private var ring1Scale: CGFloat = 0.1
    @State private var ring2Scale: CGFloat = 0.1
    @State private var ring3Scale: CGFloat = 0.1
    @State private var ring1Opacity: CGFloat = 1.0
    @State private var ring2Opacity: CGFloat = 1.0
    @State private var ring3Opacity: CGFloat = 1.0

    private let expandedScale: CGFloat = 2.5

    var body: some View {
        ZStack {
            Circle()
                .stroke(DiamerisColors.accentPrimaryLight, lineWidth: 3)
                .scaleEffect(ring1Scale)
                .opacity(ring1Opacity)

            Circle()
                .stroke(DiamerisColors.accentSecondaryLight, lineWidth: 2)
                .scaleEffect(ring2Scale)
                .opacity(ring2Opacity)

            Circle()
                .stroke(DiamerisColors.accentPrimaryLight.opacity(Opacity.half), lineWidth: 1.5)
                .scaleEffect(ring3Scale)
                .opacity(ring3Opacity)
        }
        .onAppear {
            animateRings()
        }
    }

    private func animateRings() {
        withAnimation(.easeOut(duration: AnimationDuration.celebration)) {
            ring1Scale = expandedScale
            ring1Opacity = 0
        }

        withAnimation(.easeOut(duration: AnimationDuration.celebration).delay(StaggerDelay.comfortable)) {
            ring2Scale = expandedScale
            ring2Opacity = 0
        }

        withAnimation(.easeOut(duration: AnimationDuration.celebration).delay(StaggerDelay.initial)) {
            ring3Scale = expandedScale
            ring3Opacity = 0
        }
    }
}

/// Success checkmark with bounce animation
struct AnimatedCheckmark: View {
    @State private var scale: CGFloat = 0.1
    @State private var rotation: Double = -30
    @State private var opacity: CGFloat = 0

    var body: some View {
        Image(systemName: "checkmark.circle.fill")
            .iconHero()
            .foregroundStyle(DiamerisColors.accentSecondaryLight)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .onAppear {
                withAnimation(SpringPreset.bouncy) {
                    scale = 1.0
                    rotation = 0
                    opacity = 1.0
                }
            }
    }
}

/// Combined celebration view for completion screen
struct CompletionCelebration: View {
    @State private var showConfetti = false
    @State private var showRings = false

    var body: some View {
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
        .onAppear {
            HapticManager.success()
            showRings = true
            DispatchQueue.main.asyncAfter(deadline: .now() + AnimationDuration.fast) {
                showConfetti = true
            }
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
