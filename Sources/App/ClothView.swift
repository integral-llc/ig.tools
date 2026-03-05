import SwiftUI

struct ClothView: View {
    @Bindable var cloth: ClothState

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                drawConstraints(context: context)
                drawParticles(context: context)
            }
            .onChange(of: timeline.date) { oldDate, newDate in
                let dt = min(Float(newDate.timeIntervalSince(oldDate)), 1.0 / 30.0)
                cloth.update(dt: dt)
            }
        }
        .gesture(dragGesture)
    }

    // MARK: - Drawing

    private func drawConstraints(context: GraphicsContext) {
        var path = Path()
        for c in cloth.constraints {
            let a = cloth.particles[c.indexA].position
            let b = cloth.particles[c.indexB].position
            path.move(to: CGPoint(x: CGFloat(a.x), y: CGFloat(a.y)))
            path.addLine(to: CGPoint(x: CGFloat(b.x), y: CGFloat(b.y)))
        }
        context.stroke(path, with: .color(.secondary.opacity(0.3)), lineWidth: 0.5)
    }

    private func drawParticles(context: GraphicsContext) {
        let dotRadius: CGFloat = 2
        for particle in cloth.particles {
            let rect = CGRect(
                x: CGFloat(particle.position.x) - dotRadius,
                y: CGFloat(particle.position.y) - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            )
            let color: Color = particle.isPinned ? .blue : .primary.opacity(0.6)
            context.fill(Ellipse().path(in: rect), with: .color(color))
        }
    }

    // MARK: - Interaction

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let point = SIMD2<Float>(Float(value.location.x), Float(value.location.y))
                if cloth.draggedParticleIndex == nil {
                    cloth.draggedParticleIndex = cloth.nearestParticle(to: point, within: 20)
                }
                if let idx = cloth.draggedParticleIndex {
                    cloth.moveParticle(at: idx, to: point)
                }
            }
            .onEnded { _ in
                cloth.draggedParticleIndex = nil
            }
    }
}
