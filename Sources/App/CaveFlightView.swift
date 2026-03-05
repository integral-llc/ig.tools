import SwiftUI

struct CaveFlightView: View {
    @State private var time: Double = 0

    private let segmentCount = 24
    private let segmentSpacing: Double = 2.0
    private let baseHalfW: Double = 2.8
    private let baseHalfH: Double = 2.2
    private let focalLength: Double = 180.0
    private let speed: Double = 4.0
    private let turnFreq: Double = 0.05
    private let turnAmp: Double = 3.0

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                drawTunnel(context: context, size: size)
            }
            .onChange(of: timeline.date) { _, newDate in
                time = newDate.timeIntervalSinceReferenceDate
            }
        }
    }

    // MARK: - Rendering

    private func drawTunnel(context: GraphicsContext, size: CGSize) {
        let cx = size.width / 2
        let cy = size.height / 2
        let cameraZ = time * speed

        // Camera follows the tunnel center
        let camX = pathX(cameraZ)
        let camY = pathY(cameraZ)

        // Look-ahead: camera steers toward where the tunnel goes
        let lookAhead: Double = 10
        let lookDirX = pathX(cameraZ + lookAhead) - camX
        let lookDirY = pathY(cameraZ + lookAhead) - camY

        // Black void
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))

        // Project cross-section corners for each segment
        let firstWorldZ = (floor(cameraZ / segmentSpacing) + 1) * segmentSpacing

        var sections: [(
            tl: CGPoint, tr: CGPoint, bl: CGPoint, br: CGPoint,
            viewZ: Double, segIdx: Int
        )] = []

        for i in 0...segmentCount {
            let worldZ = firstWorldZ + Double(i) * segmentSpacing
            let viewZ = worldZ - cameraZ
            guard viewZ > 0.5 else { continue }

            // Tunnel center in view-space (with look-ahead rotation)
            let relX = (pathX(worldZ) - camX) - lookDirX * (viewZ / lookAhead)
            let relY = (pathY(worldZ) - camY) - lookDirY * (viewZ / lookAhead)
            let scale = focalLength / viewZ

            // Per-wall noise displacement → rocky irregular mine shaft
            let lw = baseHalfW + noise1D(worldZ * 0.5 + 10) * 0.35
            let rw = baseHalfW + noise1D(worldZ * 0.5 + 20) * 0.35
            let th = baseHalfH + noise1D(worldZ * 0.5 + 30) * 0.25
            let bh = baseHalfH + noise1D(worldZ * 0.5 + 40) * 0.25

            let tl = CGPoint(x: cx + (relX - lw) * scale, y: cy + (relY - th) * scale)
            let tr = CGPoint(x: cx + (relX + rw) * scale, y: cy + (relY - th) * scale)
            let bl = CGPoint(x: cx + (relX - lw) * scale, y: cy + (relY + bh) * scale)
            let br = CGPoint(x: cx + (relX + rw) * scale, y: cy + (relY + bh) * scale)

            let segIdx = Int(round(worldZ / segmentSpacing))
            sections.append((tl, tr, bl, br, viewZ, segIdx))
        }

        // Draw wall quads back to front (painter's algorithm)
        for i in stride(from: sections.count - 2, through: 0, by: -1) {
            let far = sections[i + 1]
            let near = sections[i]
            let avgZ = (far.viewZ + near.viewZ) / 2
            let headlight = 1.0 / (1.0 + avgZ * avgZ * 0.005)

            // Ceiling — dark brownish-red
            fillQuad(
                context: context,
                far.tl, far.tr, near.tr, near.tl,
                hue: 0.02, sat: 0.35, bright: 0.13 * headlight * 4
            )

            // Floor — darker gray-brown
            fillQuad(
                context: context,
                far.bl, far.br, near.br, near.bl,
                hue: 0.06, sat: 0.2, bright: 0.08 * headlight * 4
            )

            // Left wall — magenta light strip every 5 segments
            let leftIsLight = far.segIdx % 5 == 0
            fillQuad(
                context: context,
                far.tl, far.bl, near.bl, near.tl,
                hue: leftIsLight ? 0.85 : 0.04,
                sat: leftIsLight ? 0.8 : 0.3,
                bright: (leftIsLight ? 0.5 : 0.16) * headlight * 3.5
            )

            // Right wall — offset light strip pattern
            let rightIsLight = far.segIdx % 5 == 2
            fillQuad(
                context: context,
                far.tr, far.br, near.br, near.tr,
                hue: rightIsLight ? 0.85 : 0.04,
                sat: rightIsLight ? 0.8 : 0.3,
                bright: (rightIsLight ? 0.5 : 0.16) * headlight * 3.5
            )

            // Cross-section edge frame (panel seam lines)
            strokeFrame(
                context: context,
                near.tl, near.tr, near.br, near.bl,
                alpha: headlight * 0.2
            )
        }

        drawCrosshair(context: context, cx: cx, cy: cy)
    }

    // MARK: - Drawing helpers

    private func fillQuad(
        context: GraphicsContext,
        _ p0: CGPoint, _ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint,
        hue: Double, sat: Double, bright: Double
    ) {
        var path = Path()
        path.move(to: p0)
        path.addLine(to: p1)
        path.addLine(to: p2)
        path.addLine(to: p3)
        path.closeSubpath()
        let b = max(0.015, min(0.95, bright))
        context.fill(path, with: .color(Color(hue: hue, saturation: sat, brightness: b)))
    }

    private func strokeFrame(
        context: GraphicsContext,
        _ p0: CGPoint, _ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint,
        alpha: Double
    ) {
        var path = Path()
        path.move(to: p0)
        path.addLine(to: p1)
        path.addLine(to: p2)
        path.addLine(to: p3)
        path.closeSubpath()
        context.stroke(path, with: .color(.white.opacity(alpha)), lineWidth: 0.6)
    }

    // MARK: - Tunnel path (layered noise for smooth organic turns)

    private func pathX(_ z: Double) -> Double {
        noise1D(z * turnFreq) * turnAmp
            + noise1D(z * turnFreq * 0.4 + 200) * turnAmp * 0.6
    }

    private func pathY(_ z: Double) -> Double {
        noise1D(z * turnFreq + 100) * turnAmp * 0.6
            + noise1D(z * turnFreq * 0.3 + 300) * turnAmp * 0.3
    }

    // MARK: - HUD

    private func drawCrosshair(context: GraphicsContext, cx: Double, cy: Double) {
        let gap: Double = 3
        let arm: Double = 7

        var path = Path()
        path.move(to: CGPoint(x: cx - gap - arm, y: cy))
        path.addLine(to: CGPoint(x: cx - gap, y: cy))
        path.move(to: CGPoint(x: cx + gap, y: cy))
        path.addLine(to: CGPoint(x: cx + gap + arm, y: cy))
        path.move(to: CGPoint(x: cx, y: cy - gap - arm))
        path.addLine(to: CGPoint(x: cx, y: cy - gap))
        path.move(to: CGPoint(x: cx, y: cy + gap))
        path.addLine(to: CGPoint(x: cx, y: cy + gap + arm))

        context.stroke(path, with: .color(.green.opacity(0.5)), lineWidth: 1)

        let r: Double = 1.5
        context.fill(
            Ellipse().path(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)),
            with: .color(.green.opacity(0.5))
        )
    }

    // MARK: - Noise

    private func noise1D(_ x: Double) -> Double {
        let xi = Int(floor(x)) & 0xFF
        let xf = x - floor(x)
        let a = hash1D(xi)
        let b = hash1D(xi + 1)
        let t = xf * xf * (3 - 2 * xf)
        return a + (b - a) * t
    }

    private func hash1D(_ n: Int) -> Double {
        var x = n
        x = ((x >> 13) ^ x) &* 1274126177
        x = x &* x &* x &* (x &* 6 &+ 1274126177)
        return Double(x & 0x7FFFFFFF) / Double(0x7FFFFFFF) * 2 - 1
    }
}
