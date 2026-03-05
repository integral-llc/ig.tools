import SwiftUI

struct CaveFlightView: View {
    @State private var time: Double = 0

    private let ringCount = 20
    private let sides = 8
    private let flySpeed: Double = 0.8
    private let turnAmplitude: Double = 0.15

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
        let maxRadius = max(size.width, size.height) * 0.75

        // Scroll phase — rings continuously stream toward viewer
        let scroll = fmod(time * flySpeed, 1.0)

        // Build ring data from far (small) to near (large)
        var rings: [(poly: Path, depth: Double)] = []

        for i in 0...ringCount {
            // Depth: 0 = vanishing point, 1 = camera
            let rawDepth = (Double(i) + scroll) / Double(ringCount)
            let depth = min(rawDepth, 1.0)

            // Exponential scaling for perspective
            let scale = depth * depth
            let radius = maxRadius * scale

            // Tunnel center drifts with noise for turns
            let depthSeed = Double(i) + floor(time * flySpeed)
            let offsetX = noise1D(depthSeed * 0.3 + 10) * size.width * turnAmplitude * depth
            let offsetY = noise1D(depthSeed * 0.3 + 50) * size.height * turnAmplitude * depth

            let centerX = cx + offsetX
            let centerY = cy + offsetY

            let poly = caveRing(
                center: CGPoint(x: centerX, y: centerY),
                radius: radius,
                seed: depthSeed
            )
            rings.append((poly: poly, depth: depth))
        }

        // Fill background (the void beyond the tunnel)
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))

        // Draw from far to near: fill the wall between consecutive rings
        for i in 0..<rings.count - 1 {
            let outerRing = rings[i + 1]
            let innerRing = rings[i]

            // Wall shape = outer minus inner (even-odd fill)
            var wallPath = outerRing.poly
            wallPath.addPath(innerRing.poly)

            let depth = outerRing.depth
            let hue = fmod(depth * 1.5 + time * 0.08, 1.0)
            let brightness = 0.15 + depth * 0.45
            let saturation = 0.5 + depth * 0.3

            context.fill(
                wallPath,
                with: .color(Color(hue: hue, saturation: saturation, brightness: brightness)),
                style: FillStyle(eoFill: true)
            )

            // Edge line on inner ring for rocky definition
            let lineOpacity = 0.1 + depth * 0.3
            context.stroke(
                innerRing.poly,
                with: .color(.white.opacity(lineOpacity)),
                lineWidth: 0.5
            )
        }

        // Subtle crosshair / HUD dot at center
        let dotSize: CGFloat = 3
        let dotRect = CGRect(x: cx - dotSize / 2, y: cy - dotSize / 2, width: dotSize, height: dotSize)
        context.fill(Ellipse().path(in: dotRect), with: .color(.white.opacity(0.25)))
    }

    // MARK: - Cave ring geometry

    private func caveRing(center: CGPoint, radius: Double, seed: Double) -> Path {
        var path = Path()
        for s in 0...sides {
            let angle = Double(s) / Double(sides) * .pi * 2

            // Noise-based vertex displacement for rocky walls
            let noiseVal = noise1D(seed * 2.7 + Double(s) * 1.3)
            let displacement = 1.0 + noiseVal * 0.25
            let r = radius * displacement

            let x = center.x + cos(angle) * r
            let y = center.y + sin(angle) * r

            if s == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
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
