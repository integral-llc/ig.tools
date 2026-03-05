import SwiftUI

struct RubiksCubeView: View {
    @State private var time: Double = 0
    @State private var rotX: Double = -0.5
    @State private var rotY: Double = 0.6
    @State private var baseRotX: Double = -0.5
    @State private var baseRotY: Double = 0.6

    private let cellSize: Double = 18
    private let cellGap: Double = 2
    private let focal: Double = 400
    private let camZ: Double = 320
    private let maxSpread: Double = 1.5
    private let moveCount = 15
    private let solveSpeed: Double = 0.28

    // Phase durations
    private let restA: Double = 0.5
    private let explDur: Double = 2.5
    private let restB: Double = 0.5
    private let restC: Double = 0.8
    private var solveDur: Double { Double(moveCount) * solveSpeed }
    private var cycle: Double { restA + explDur + restB + solveDur + restC }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in drawScene(ctx: ctx, size: size) }
                .onChange(of: timeline.date) { _, d in
                    time = d.timeIntervalSinceReferenceDate
                }
        }
        .gesture(
            DragGesture()
                .onChanged { v in
                    rotX = baseRotX + v.translation.height * 0.008
                    rotY = baseRotY + v.translation.width * 0.008
                }
                .onEnded { _ in baseRotX = rotX; baseRotY = rotY }
        )
    }

    // MARK: - Types

    private struct Clet {
        let id: SIMD3<Int>
        var pos: SIMD3<Int>
        var bx: SIMD3<Int>
        var by: SIMD3<Int>
        var bz: SIMD3<Int>
    }

    private struct Mv {
        let axis: Int
        let layer: Int
        let dir: Int
        var inv: Mv { Mv(axis: axis, layer: layer, dir: -dir) }
    }

    // MARK: - Rendering

    private func drawScene(ctx: GraphicsContext, size: CGSize) {
        let cx = size.width / 2
        let cy = size.height / 2
        ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))

        let ct = time.truncatingRemainder(dividingBy: cycle)
        let cn = Int(time / cycle)
        let moves = genScramble(seed: cn)
        let solved = makeSolved()
        let scrambled = applyAll(moves, to: solved)

        let gax = rotX
        let gay = rotY + time * 0.25
        let step = cellSize + cellGap
        let half = cellSize / 2
        let light = nrm(SIMD3(0.3, -0.5, -1.0))

        // Phase boundaries
        let p1 = restA
        let p2 = p1 + explDur
        let p3 = p2 + restB
        let p4 = p3 + solveDur

        // Pre-compute solve state if in solve phase
        var solveCubs: [Clet]?
        var solMv: Mv?
        var solFrac: Double = 0
        if ct >= p3 && ct < p4 {
            let st = ct - p3
            let mi = Int(st / solveSpeed)
            solFrac = easeIO((st - Double(mi) * solveSpeed) / solveSpeed)
            let rev = moves.reversed().map { $0.inv }
            solveCubs = applyAll(Array(rev.prefix(min(mi, rev.count))), to: scrambled)
            solMv = mi < rev.count ? rev[mi] : nil
        }

        let localDirs: [SIMD3<Double>] = [
            SIMD3(1, 0, 0), SIMD3(-1, 0, 0),
            SIMD3(0, 1, 0), SIMD3(0, -1, 0),
            SIMD3(0, 0, 1), SIMD3(0, 0, -1),
        ]

        typealias FD = (pts: [CGPoint], z: Double, h: Double, s: Double, b: Double)
        var faces: [FD] = []

        for i in 0..<26 {
            // Determine per-cubelet render state
            var ctr: SIMD3<Double>
            var bxF: SIMD3<Double>
            var byF: SIMD3<Double>
            var bzF: SIMD3<Double>
            var expl: Double = 0
            var tmbl: Double = 0
            var ident: SIMD3<Int>

            if ct < p1 || ct >= p4 {
                let c = solved[i]
                ctr = dbl(c.pos) * step
                bxF = dbl(c.bx); byF = dbl(c.by); bzF = dbl(c.bz)
                ident = c.id
            } else if ct < p2 {
                let t = (ct - p1) / explDur
                let e = (1 - cos(t * 2 * .pi)) / 2
                let drift = sstep(t, e0: 0.35, e1: 0.65)
                expl = e * maxSpread
                tmbl = e
                let sc = solved[i]
                let dc = scrambled[i]
                ctr = dbl(sc.pos) * step * (1 - drift) + dbl(dc.pos) * step * drift
                ident = sc.id
                if t < 0.5 {
                    bxF = dbl(sc.bx); byF = dbl(sc.by); bzF = dbl(sc.bz)
                } else {
                    bxF = dbl(dc.bx); byF = dbl(dc.by); bzF = dbl(dc.bz)
                }
            } else if ct < p3 {
                let c = scrambled[i]
                ctr = dbl(c.pos) * step
                bxF = dbl(c.bx); byF = dbl(c.by); bzF = dbl(c.bz)
                ident = c.id
            } else {
                let c = solveCubs![i]
                ident = c.id
                if let m = solMv, c.pos[m.axis] == m.layer {
                    let ang = solFrac * Double(m.dir) * .pi / 2
                    ctr = rotAx(dbl(c.pos) * step, a: m.axis, ang: ang)
                    bxF = rotAx(dbl(c.bx), a: m.axis, ang: ang)
                    byF = rotAx(dbl(c.by), a: m.axis, ang: ang)
                    bzF = rotAx(dbl(c.bz), a: m.axis, ang: ang)
                } else {
                    ctr = dbl(c.pos) * step
                    bxF = dbl(c.bx); byF = dbl(c.by); bzF = dbl(c.bz)
                }
            }

            // Explode offset uses identity direction for stable radial spread
            let ectr = ctr + dbl(ident) * step * expl

            // Tumble
            let seed = Double(ident.x * 7 + ident.y * 13 + ident.z * 23)
            let tAx = tmbl * .pi * 0.35 * sin(seed * 1.1 + 0.5)
            let tAy = tmbl * .pi * 0.3 * cos(seed * 0.7 + 0.3)

            // Render 6 faces
            for d in localDirs {
                let wn = bxF * d.x + byF * d.y + bzF * d.z
                let tn = rot3(wn, ax: tAx, ay: tAy)
                let rn = rot3(tn, ax: gax, ay: gay)
                guard rn.z < 0 else { continue }

                let color = stickerHSB(d: d, id: ident)
                let (t1, t2) = wTan(d, bx: bxF, by: byF, bz: bzF)
                let fc = ectr + wn * half
                let ca = fc + (-t1 - t2) * half
                let cb = fc + (t1 - t2) * half
                let cc = fc + (t1 + t2) * half
                let cd = fc + (-t1 + t2) * half

                var pts: [CGPoint] = []
                var zS: Double = 0
                for corner in [ca, cb, cc, cd] {
                    let rel = rot3(corner - ectr, ax: tAx, ay: tAy) + ectr
                    let r = rot3(rel, ax: gax, ay: gay)
                    let s = focal / (camZ + r.z)
                    pts.append(CGPoint(x: cx + r.x * s, y: cy + r.y * s))
                    zS += r.z
                }

                let sh = max(0.25, dot3(rn, light))
                faces.append((pts, zS / 4, color.0, color.1, max(0.02, color.2 * sh)))
            }
        }

        faces.sort { $0.z > $1.z }
        for f in faces {
            var p = Path()
            p.move(to: f.pts[0])
            for j in 1...3 { p.addLine(to: f.pts[j]) }
            p.closeSubpath()
            ctx.fill(p, with: .color(Color(hue: f.h, saturation: f.s, brightness: f.b)))
            ctx.stroke(p, with: .color(.black.opacity(0.7)), lineWidth: 0.8)
        }
    }

    // MARK: - Sticker Colors

    private func stickerHSB(d: SIMD3<Double>, id: SIMD3<Int>) -> (Double, Double, Double) {
        if d.x > 0.5 && id.x == 1 { return (0.0, 0.85, 0.85) }     // Red (+x)
        if d.x < -0.5 && id.x == -1 { return (0.08, 0.9, 0.9) }    // Orange (-x)
        if d.y < -0.5 && id.y == -1 { return (0.0, 0.0, 1.0) }      // White (top)
        if d.y > 0.5 && id.y == 1 { return (0.15, 0.9, 0.95) }      // Yellow (bottom)
        if d.z < -0.5 && id.z == -1 { return (0.6, 0.85, 0.8) }     // Blue (front)
        if d.z > 0.5 && id.z == 1 { return (0.35, 0.75, 0.65) }     // Green (back)
        return (0, 0, 0.12)
    }

    // MARK: - Cube State

    private func makeSolved() -> [Clet] {
        var out: [Clet] = []
        for gx in -1...1 {
            for gy in -1...1 {
                for gz in -1...1 {
                    if gx == 0 && gy == 0 && gz == 0 { continue }
                    let p = SIMD3(gx, gy, gz)
                    out.append(Clet(
                        id: p, pos: p,
                        bx: SIMD3(1, 0, 0), by: SIMD3(0, 1, 0), bz: SIMD3(0, 0, 1)
                    ))
                }
            }
        }
        return out
    }

    private func applyAll(_ moves: [Mv], to cubelets: [Clet]) -> [Clet] {
        var result = cubelets
        for m in moves { result = applyMv(m, to: result) }
        return result
    }

    private func applyMv(_ m: Mv, to cubelets: [Clet]) -> [Clet] {
        cubelets.map { c in
            guard c.pos[m.axis] == m.layer else { return c }
            return Clet(
                id: c.id,
                pos: rotI(c.pos, axis: m.axis, dir: m.dir),
                bx: rotI(c.bx, axis: m.axis, dir: m.dir),
                by: rotI(c.by, axis: m.axis, dir: m.dir),
                bz: rotI(c.bz, axis: m.axis, dir: m.dir)
            )
        }
    }

    // Rotate integer vector 90 degrees around axis
    private func rotI(_ v: SIMD3<Int>, axis: Int, dir: Int) -> SIMD3<Int> {
        switch axis {
        case 0:
            return dir > 0 ? SIMD3(v.x, -v.z, v.y) : SIMD3(v.x, v.z, -v.y)
        case 1:
            return dir > 0 ? SIMD3(v.z, v.y, -v.x) : SIMD3(-v.z, v.y, v.x)
        default:
            return dir > 0 ? SIMD3(-v.y, v.x, v.z) : SIMD3(v.y, -v.x, v.z)
        }
    }

    // MARK: - Scramble Generation

    private func genScramble(seed: Int) -> [Mv] {
        var s = seed &* 2654435761 &+ 1
        func next() -> Int {
            s = s &* 1103515245 &+ 12345
            return (s >> 16) & 0x7FFF
        }
        var moves: [Mv] = []
        var lastAxis = -1
        for _ in 0..<moveCount {
            var axis: Int
            repeat { axis = next() % 3 } while axis == lastAxis
            let layer = (next() % 2 == 0) ? 1 : -1
            let dir = (next() % 2 == 0) ? 1 : -1
            moves.append(Mv(axis: axis, layer: layer, dir: dir))
            lastAxis = axis
        }
        return moves
    }

    // MARK: - 3D Math

    // Rotate float vector around a single axis by angle
    private func rotAx(_ v: SIMD3<Double>, a: Int, ang: Double) -> SIMD3<Double> {
        let c = cos(ang), s = sin(ang)
        switch a {
        case 0: return SIMD3(v.x, v.y * c - v.z * s, v.y * s + v.z * c)
        case 1: return SIMD3(v.x * c + v.z * s, v.y, -v.x * s + v.z * c)
        default: return SIMD3(v.x * c - v.y * s, v.x * s + v.y * c, v.z)
        }
    }

    // Rotate by camera angles (Y then X)
    private func rot3(_ v: SIMD3<Double>, ax: Double, ay: Double) -> SIMD3<Double> {
        let cY = cos(ay), sY = sin(ay)
        let r = SIMD3(v.x * cY + v.z * sY, v.y, -v.x * sY + v.z * cY)
        let cX = cos(ax), sX = sin(ax)
        return SIMD3(r.x, r.y * cX - r.z * sX, r.y * sX + r.z * cX)
    }

    // World-space tangent pair for a local face direction
    private func wTan(
        _ d: SIMD3<Double>, bx: SIMD3<Double>, by: SIMD3<Double>, bz: SIMD3<Double>
    ) -> (SIMD3<Double>, SIMD3<Double>) {
        if abs(d.x) > 0.5 { return (bz, by) }
        if abs(d.y) > 0.5 { return (bx, bz) }
        return (bx, by)
    }

    private func easeIO(_ t: Double) -> Double {
        let c = max(0, min(1, t))
        return c * c * (3 - 2 * c)
    }

    private func sstep(_ x: Double, e0: Double, e1: Double) -> Double {
        let t = max(0, min(1, (x - e0) / (e1 - e0)))
        return t * t * (3 - 2 * t)
    }

    private func dbl(_ v: SIMD3<Int>) -> SIMD3<Double> {
        SIMD3(Double(v.x), Double(v.y), Double(v.z))
    }

    private func nrm(_ v: SIMD3<Double>) -> SIMD3<Double> {
        v / sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
    }

    private func dot3(_ a: SIMD3<Double>, _ b: SIMD3<Double>) -> Double {
        a.x * b.x + a.y * b.y + a.z * b.z
    }
}
