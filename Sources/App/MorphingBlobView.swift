import SwiftUI

struct MorphingBlobView: View {
    @State private var time: Double = 0

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                drawBlob(context: context, size: size)
            }
            .onChange(of: timeline.date) { _, newDate in
                time = newDate.timeIntervalSinceReferenceDate
            }
        }
    }

    private func drawBlob(context: GraphicsContext, size: CGSize) {
        let cx = size.width / 2
        let cy = size.height / 2
        let baseRadius = min(size.width, size.height) * 0.32
        let t = time * 0.4  // slow morph speed

        // Build blob path from radial sine deformations
        let segments = 120
        var path = Path()
        for i in 0...segments {
            let angle = Double(i) / Double(segments) * .pi * 2
            let r = baseRadius
                + sin(angle * 3 + t * 1.3) * baseRadius * 0.15
                + sin(angle * 5 - t * 0.9) * baseRadius * 0.08
                + sin(angle * 7 + t * 1.7) * baseRadius * 0.05
                + cos(angle * 2 - t * 0.6) * baseRadius * 0.10

            let x = cx + r * cos(angle)
            let y = cy + r * sin(angle)

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()

        // Soft shadow
        var shadowContext = context
        shadowContext.addFilter(.shadow(color: .accentColor.opacity(0.3), radius: 16, x: 0, y: 4))
        shadowContext.fill(path, with: .color(.accentColor.opacity(0.6)))

        // Main fill with subtle gradient
        let gradient = Gradient(colors: [
            .accentColor.opacity(0.7),
            .accentColor.opacity(0.4),
        ])
        context.fill(path, with: .linearGradient(
            gradient,
            startPoint: CGPoint(x: cx, y: cy - baseRadius),
            endPoint: CGPoint(x: cx, y: cy + baseRadius)
        ))
    }
}
