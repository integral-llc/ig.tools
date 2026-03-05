import SwiftUI

struct FractalTreeView: View {
    @State private var growth: Double = 0
    @State private var windPhase: Double = 0

    private let maxDepth = 5
    private let branchAngle: Double = .pi / 6  // 30 degrees
    private let lengthRatio: Double = 0.72

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let trunkLength = size.height * 0.28
                let startPoint = CGPoint(x: size.width / 2, y: size.height * 0.88)
                drawBranch(
                    context: context,
                    from: startPoint,
                    angle: -.pi / 2,
                    length: trunkLength,
                    depth: 0
                )
            }
            .onChange(of: timeline.date) { _, newDate in
                let t = newDate.timeIntervalSinceReferenceDate
                windPhase = t * 0.5
                // Grow to full in ~2 seconds then stay
                if growth < 1.0 {
                    growth = min(1.0, growth + 0.012)
                }
            }
        }
    }

    private func drawBranch(
        context: GraphicsContext,
        from start: CGPoint,
        angle: Double,
        length: Double,
        depth: Int
    ) {
        guard depth <= maxDepth else { return }

        // Growth animation: deeper branches appear later
        let depthProgress = Double(depth) / Double(maxDepth)
        let branchGrowth = max(0, min(1, (growth - depthProgress * 0.6) / 0.4))
        guard branchGrowth > 0 else { return }

        // Wind sway increases with depth
        let windOffset = sin(windPhase + Double(depth) * 0.8) * Double(depth) * 0.015

        let adjustedAngle = angle + windOffset
        let actualLength = length * branchGrowth

        let endX = start.x + cos(adjustedAngle) * actualLength
        let endY = start.y + sin(adjustedAngle) * actualLength
        let end = CGPoint(x: endX, y: endY)

        // Draw this branch
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)

        let lineWidth = max(0.8, 3.0 - Double(depth) * 0.45)
        let opacity = 0.7 - Double(depth) * 0.08
        context.stroke(
            path,
            with: .color(.accentColor.opacity(opacity)),
            lineWidth: lineWidth
        )

        // Recurse into child branches
        guard branchGrowth >= 1.0 else { return }

        let childLength = length * lengthRatio

        // Left branch
        drawBranch(
            context: context,
            from: end,
            angle: adjustedAngle - branchAngle,
            length: childLength,
            depth: depth + 1
        )

        // Right branch
        drawBranch(
            context: context,
            from: end,
            angle: adjustedAngle + branchAngle,
            length: childLength,
            depth: depth + 1
        )
    }
}
