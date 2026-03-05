import SwiftUI

struct DNAHelixView: View {
    @State private var phase: Double = 0

    private let strandRadius: CGFloat = 0.25
    private let rungs = 12
    private let scrollSpeed: Double = 0.6

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                drawHelix(context: context, size: size)
            }
            .onChange(of: timeline.date) { _, newDate in
                phase = newDate.timeIntervalSinceReferenceDate * scrollSpeed
            }
        }
    }

    private func drawHelix(context: GraphicsContext, size: CGSize) {
        let cx = size.width / 2
        let amplitude = size.width * strandRadius
        let steps = Int(size.height * 1.5)
        let frequency = .pi * 2 * 3 / size.height  // 3 full twists visible

        // Draw rungs (connecting bars between strands)
        let rungSpacing = size.height / CGFloat(rungs)
        for i in 0...rungs + 2 {
            let baseY = CGFloat(i) * rungSpacing
            let y = fmod(baseY + CGFloat(phase * 60).truncatingRemainder(dividingBy: size.height) + size.height, size.height)
            let angle = Double(y) * frequency + phase
            let depth = cos(angle)

            let x1 = cx + sin(angle) * amplitude
            let x2 = cx - sin(angle) * amplitude

            var path = Path()
            path.move(to: CGPoint(x: x1, y: y))
            path.addLine(to: CGPoint(x: x2, y: y))

            let rungOpacity = 0.15 + abs(depth) * 0.15
            context.stroke(path, with: .color(.accentColor.opacity(rungOpacity)), lineWidth: 2)
        }

        // Draw strand A
        drawStrand(context: context, size: size, cx: cx, amplitude: amplitude,
                   frequency: frequency, steps: steps, invert: false)

        // Draw strand B
        drawStrand(context: context, size: size, cx: cx, amplitude: amplitude,
                   frequency: frequency, steps: steps, invert: true)
    }

    private func drawStrand(
        context: GraphicsContext, size: CGSize, cx: CGFloat,
        amplitude: CGFloat, frequency: Double, steps: Int, invert: Bool
    ) {
        let sign: CGFloat = invert ? -1 : 1

        // Draw as segments with depth-based opacity for 3D illusion
        let segmentCount = steps
        for i in 0..<segmentCount {
            let y0 = CGFloat(i) / CGFloat(segmentCount) * size.height
            let y1 = CGFloat(i + 1) / CGFloat(segmentCount) * size.height

            let angle0 = Double(y0) * frequency + phase
            let angle1 = Double(y1) * frequency + phase

            let x0 = cx + sign * sin(angle0) * amplitude
            let x1 = cx + sign * sin(angle1) * amplitude

            let depth = cos(angle0)
            let opacity = invert
                ? (depth > 0 ? 0.25 : 0.6)
                : (depth > 0 ? 0.6 : 0.25)

            var path = Path()
            path.move(to: CGPoint(x: x0, y: y0))
            path.addLine(to: CGPoint(x: x1, y: y1))
            context.stroke(
                path,
                with: .color(.accentColor.opacity(opacity)),
                lineWidth: 2.5
            )
        }
    }
}
