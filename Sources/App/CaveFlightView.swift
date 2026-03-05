import SwiftUI

struct CaveFlightView: View {
    @State private var time: Double = 0

    private let scrollSpeed: Double = 40
    private let caveGap: Double = 0.45      // fraction of height guaranteed open
    private let planeSize: CGFloat = 14

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                drawCave(context: context, size: size)
            }
            .onChange(of: timeline.date) { _, newDate in
                time = newDate.timeIntervalSinceReferenceDate
            }
        }
    }

    // MARK: - Drawing

    private func drawCave(context: GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let offset = time * scrollSpeed

        // Background layers (back to front, slower to faster)
        drawCaveLayer(context: context, size: size, offset: offset * 0.3,
                      noiseScale: 0.006, gapFraction: 0.60, opacity: 0.12, hueShift: 0.0)
        drawCaveLayer(context: context, size: size, offset: offset * 0.6,
                      noiseScale: 0.009, gapFraction: 0.52, opacity: 0.22, hueShift: 0.15)
        drawCaveLayer(context: context, size: size, offset: offset,
                      noiseScale: 0.013, gapFraction: caveGap, opacity: 0.40, hueShift: 0.3)

        // Plane
        let planeX = w * 0.3
        let centerY = h * 0.5
        let planeY = centerY + sin(time * 0.7) * h * 0.06
        let tilt = cos(time * 0.7) * 0.15  // subtle pitch
        drawPlane(context: context, at: CGPoint(x: planeX, y: planeY), tilt: tilt)
    }

    private func drawCaveLayer(
        context: GraphicsContext, size: CGSize, offset: Double,
        noiseScale: Double, gapFraction: Double, opacity: Double, hueShift: Double
    ) {
        let w = size.width
        let h = size.height
        let step: CGFloat = 2

        // Generate top and bottom wall Y positions
        var topPath = Path()
        var bottomPath = Path()

        topPath.move(to: CGPoint(x: 0, y: 0))
        bottomPath.move(to: CGPoint(x: 0, y: h))

        let columns = Int(w / step) + 1
        for i in 0...columns {
            let x = CGFloat(i) * step
            let noiseX = (Double(x) + offset) * noiseScale

            let centerWobble = noise1D(noiseX * 0.5 + 100) * 0.15
            let center = 0.5 + centerWobble

            let topNoise = noise1D(noiseX) * 0.2
            let bottomNoise = noise1D(noiseX + 50) * 0.2

            let halfGap = gapFraction / 2
            let topY = (center - halfGap + topNoise) * h
            let bottomY = (center + halfGap - bottomNoise) * h

            topPath.addLine(to: CGPoint(x: x, y: max(0, topY)))
            bottomPath.addLine(to: CGPoint(x: x, y: min(h, bottomY)))
        }

        // Close top wall path
        topPath.addLine(to: CGPoint(x: w, y: 0))
        topPath.closeSubpath()

        // Close bottom wall path
        bottomPath.addLine(to: CGPoint(x: w, y: h))
        bottomPath.closeSubpath()

        // Rainbow gradient that scrolls with the cave
        let gradientPhase = fmod(offset * 0.003 + hueShift, 1.0)
        let colors = rainbowColors(phase: gradientPhase, opacity: opacity)
        let gradient = Gradient(colors: colors)
        let shading = GraphicsContext.Shading.linearGradient(
            gradient,
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: w, y: 0)
        )

        context.fill(topPath, with: shading)
        context.fill(bottomPath, with: shading)
    }

    private func drawPlane(context: GraphicsContext, at point: CGPoint, tilt: Double) {
        var ctx = context
        ctx.translateBy(x: point.x, y: point.y)
        ctx.rotate(by: .radians(tilt))

        // Simple triangle plane silhouette
        var body = Path()
        body.move(to: CGPoint(x: planeSize * 0.6, y: 0))            // nose
        body.addLine(to: CGPoint(x: -planeSize * 0.4, y: -planeSize * 0.35))  // top wing
        body.addLine(to: CGPoint(x: -planeSize * 0.3, y: 0))         // mid
        body.addLine(to: CGPoint(x: -planeSize * 0.4, y: planeSize * 0.35))   // bottom wing
        body.closeSubpath()

        // Tail fin
        var tail = Path()
        tail.move(to: CGPoint(x: -planeSize * 0.3, y: 0))
        tail.addLine(to: CGPoint(x: -planeSize * 0.55, y: -planeSize * 0.2))
        tail.addLine(to: CGPoint(x: -planeSize * 0.5, y: 0))
        tail.closeSubpath()

        ctx.addFilter(.shadow(color: .white.opacity(0.4), radius: 4))
        ctx.fill(body, with: .color(.white.opacity(0.85)))
        ctx.fill(tail, with: .color(.white.opacity(0.7)))
    }

    // MARK: - Noise

    /// Simple value noise with cosine interpolation — smooth enough for cave walls
    private func noise1D(_ x: Double) -> Double {
        let xi = Int(floor(x)) & 0xFF
        let xf = x - floor(x)

        let a = hash1D(xi)
        let b = hash1D(xi + 1)

        // Smoothstep interpolation
        let t = xf * xf * (3 - 2 * xf)
        return a + (b - a) * t
    }

    private func hash1D(_ n: Int) -> Double {
        // Simple integer hash → [−1, 1]
        var x = n
        x = ((x >> 13) ^ x) &* 1274126177
        x = x &* x &* x &* (x &* 6 &+ 1274126177)
        return Double(x & 0x7FFFFFFF) / Double(0x7FFFFFFF) * 2 - 1
    }

    // MARK: - Color

    private func rainbowColors(phase: Double, opacity: Double) -> [Color] {
        (0..<6).map { i in
            let hue = fmod(phase + Double(i) / 6.0, 1.0)
            return Color(hue: hue, saturation: 0.6, brightness: 0.9, opacity: opacity)
        }
    }
}
