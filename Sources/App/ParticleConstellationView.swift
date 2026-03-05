import SwiftUI

struct ConstellationParticle {
    var position: CGPoint
    var velocity: CGVector
}

struct ParticleConstellationView: View {
    @State private var particles: [ConstellationParticle] = []
    @State private var size: CGSize = .zero

    private let particleCount = 25
    private let connectionDistance: CGFloat = 80
    private let speed: CGFloat = 15

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, canvasSize in
                if size != canvasSize {
                    DispatchQueue.main.async { size = canvasSize }
                }
                drawConnections(context: context)
                drawParticles(context: context)
            }
            .onChange(of: timeline.date) { oldDate, newDate in
                let dt = min(CGFloat(newDate.timeIntervalSince(oldDate)), 1.0 / 30.0)
                updateParticles(dt: dt)
            }
        }
        .onAppear {
            seedParticles()
        }
    }

    private func seedParticles() {
        // Use a fixed-seed random for reproducible initial layout
        var rng = SystemRandomNumberGenerator()
        particles = (0..<particleCount).map { _ in
            ConstellationParticle(
                position: CGPoint(
                    x: CGFloat.random(in: 20...200, using: &rng),
                    y: CGFloat.random(in: 20...350, using: &rng)
                ),
                velocity: CGVector(
                    dx: CGFloat.random(in: -speed...speed, using: &rng),
                    dy: CGFloat.random(in: -speed...speed, using: &rng)
                )
            )
        }
    }

    private func updateParticles(dt: CGFloat) {
        guard size.width > 0 else { return }
        for i in particles.indices {
            particles[i].position.x += particles[i].velocity.dx * dt
            particles[i].position.y += particles[i].velocity.dy * dt

            // Bounce off edges
            if particles[i].position.x < 0 || particles[i].position.x > size.width {
                particles[i].velocity.dx *= -1
                particles[i].position.x = max(0, min(size.width, particles[i].position.x))
            }
            if particles[i].position.y < 0 || particles[i].position.y > size.height {
                particles[i].velocity.dy *= -1
                particles[i].position.y = max(0, min(size.height, particles[i].position.y))
            }
        }
    }

    private func drawConnections(context: GraphicsContext) {
        for i in 0..<particles.count {
            for j in (i + 1)..<particles.count {
                let dx = particles[j].position.x - particles[i].position.x
                let dy = particles[j].position.y - particles[i].position.y
                let dist = sqrt(dx * dx + dy * dy)
                if dist < connectionDistance {
                    let opacity = 1.0 - (dist / connectionDistance)
                    var path = Path()
                    path.move(to: particles[i].position)
                    path.addLine(to: particles[j].position)
                    context.stroke(
                        path,
                        with: .color(.accentColor.opacity(opacity * 0.4)),
                        lineWidth: 0.8
                    )
                }
            }
        }
    }

    private func drawParticles(context: GraphicsContext) {
        let radius: CGFloat = 2.5
        for particle in particles {
            let rect = CGRect(
                x: particle.position.x - radius,
                y: particle.position.y - radius,
                width: radius * 2,
                height: radius * 2
            )
            context.fill(Ellipse().path(in: rect), with: .color(.accentColor.opacity(0.7)))
        }
    }
}
