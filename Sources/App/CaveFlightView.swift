import SwiftUI

struct CaveFlightView: View {
    @State private var time: Double = 0

    private let segmentCount = 28
    private let segmentSpacing: Double = 1.5
    private let sides = 6
    private let baseRadius: Double = 2.2
    private let focalLength: Double = 200.0
    private let speed: Double = 3.5
    private let turnFreq: Double = 0.07
    private let turnAmp: Double = 2.8

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

    // MARK: - Tunnel rendering

    private func drawTunnel(context: GraphicsContext, size: CGSize) {
        let cx = size.width / 2
        let cy = size.height / 2
        let cameraZ = time * speed

        // Camera follows the tunnel path
        let camX = pathX(cameraZ)
        let camY = pathY(cameraZ)

        // Look-ahead steering — camera rotates toward where the path goes
        let lookAhead: Double = 8
        let lookDirX = pathX(cameraZ + lookAhead) - camX
        let lookDirY = pathY(cameraZ + lookAhead) - camY

        // Background: black void
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))

        // Generate projected cross-sections from camera forward
        let firstWorldZ = (floor(cameraZ / segmentSpacing) + 1) * segmentSpacing

        var sections: [(points: [CGPoint], viewZ: Double, worldZ: Double)] = []

        for i in 0...segmentCount {
            let worldZ = firstWorldZ + Double(i) * segmentSpacing
            let viewZ = worldZ - cameraZ
            guard viewZ > 0.3 else { continue }

            let tunnelCx = pathX(worldZ)
            let tunnelCy = pathY(worldZ)

            // View-space with look-ahead rotation (small-angle approx)
            let relX = (tunnelCx - camX) - lookDirX * (viewZ / lookAhead)
            let relY = (tunnelCy - camY) - lookDirY * (viewZ / lookAhead)

            let scale = focalLength / viewZ

            var projected: [CGPoint] = []
            for s in 0..<sides {
                // π/6 rotation gives flat bottom edge (mine floor)
                let angle = Double(s) / Double(sides) * .pi * 2 + .pi / 6
                let rockNoise = 1.0 + noise1D(worldZ * 0.5 + Double(s) * 4.3) * 0.22
                let r = baseRadius * rockNoise

                let vx = relX + cos(angle) * r
                let vy = relY + sin(angle) * r

                projected.append(CGPoint(x: cx + vx * scale, y: cy + vy * scale))
            }
            sections.append((projected, viewZ, worldZ))
        }

        // Draw wall quads back-to-front (painter's algorithm)
        for i in stride(from: sections.count - 2, through: 0, by: -1) {
            let far = sections[i + 1]
            let near = sections[i]

            for s in 0..<sides {
                let ns = (s + 1) % sides

                var quad = Path()
                quad.move(to: far.points[s])
                quad.addLine(to: far.points[ns])
                quad.addLine(to: near.points[ns])
                quad.addLine(to: near.points[s])
                quad.closeSubpath()

                // Headlight: inverse-square falloff from camera
                let avgZ = (far.viewZ + near.viewZ) / 2
                let headlight = 1.0 / (1.0 + avgZ * avgZ * 0.008)

                // Face-dependent shading (top faces brightest → overhead lamp feel)
                let faceAngle = Double(s) / Double(sides) * .pi * 2 + .pi / 6
                let faceLighting = 0.3 + 0.7 * max(0, -sin(faceAngle))

                var brightness = headlight * faceLighting * 0.8

                // Rock wall color: warm brown/gray
                var hue = 0.07 + noise1D(far.worldZ * 0.15 + Double(s) * 2) * 0.04
                var sat = 0.25 + headlight * 0.15

                // Mining lights: occasional amber glow panels
                let segIdx = Int(round(far.worldZ / segmentSpacing))
                if segIdx % 6 == 0 && s == 1 {
                    hue = 0.12
                    sat = 0.8
                    brightness = min(brightness * 2.5, 0.9)
                }

                context.fill(quad, with: .color(Color(
                    hue: hue, saturation: sat, brightness: max(0.02, brightness)
                )))

                // Polygon edge wireframe (retro 3D look)
                let edgeAlpha = headlight * 0.35
                context.stroke(quad, with: .color(.white.opacity(edgeAlpha)), lineWidth: 0.8)
            }
        }

        // HUD crosshair
        drawCrosshair(context: context, cx: cx, cy: cy)
    }

    // MARK: - Tunnel path (layered noise for organic turns)

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

        let dotR: Double = 1.5
        context.fill(
            Ellipse().path(in: CGRect(x: cx - dotR, y: cy - dotR, width: dotR * 2, height: dotR * 2)),
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
