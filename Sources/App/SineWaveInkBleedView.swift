import SwiftUI

struct SineWaveInkBleedView: View {
    @State private var phase: Double = 0

    private let waveConfigs: [(amplitude: Double, frequency: Double, phaseOffset: Double, opacity: Double)] = [
        (amplitude: 0.18, frequency: 1.5, phaseOffset: 0, opacity: 0.5),
        (amplitude: 0.14, frequency: 2.0, phaseOffset: 2.1, opacity: 0.35),
        (amplitude: 0.10, frequency: 2.8, phaseOffset: 4.2, opacity: 0.25),
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                drawWaves(context: context, size: size)
            }
            .onChange(of: timeline.date) { _, newDate in
                phase = newDate.timeIntervalSinceReferenceDate * 0.8
            }
        }
    }

    private func drawWaves(context: GraphicsContext, size: CGSize) {
        for config in waveConfigs {
            var path = Path()
            let steps = Int(size.width)
            let midY = size.height / 2

            for x in 0...steps {
                let normalizedX = Double(x) / Double(steps)
                let angle = normalizedX * .pi * 2 * config.frequency + phase + config.phaseOffset
                let y = midY + sin(angle) * size.height * config.amplitude

                if x == 0 {
                    path.move(to: CGPoint(x: CGFloat(x), y: y))
                } else {
                    path.addLine(to: CGPoint(x: CGFloat(x), y: y))
                }
            }

            context.stroke(
                path,
                with: .color(.accentColor.opacity(config.opacity)),
                style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
            )
        }
    }
}
