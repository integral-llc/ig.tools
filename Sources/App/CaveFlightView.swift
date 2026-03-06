import SwiftUI

struct CaveFlightView: View {
    @State private var startDate: Date?
    @State private var elapsed: Double = 0

    private let sectionCount = 40
    private let sectionStep: Double = 1.4
    private let segmentSpacing: Double = 2.0
    private let baseHalfW: Double = 2.8
    private let baseHalfH: Double = 2.2
    private let focalLength: Double = 138.0
    private let ambientBrightness: Double = 0.01
    private let surfaceBrightnessFloor: Double = 0.06
    private let accentHues: [Double] = [0.0, 0.04, 0.08, 0.12, 0.95]
    private let speed: Double = 6.0
    private let branchDepth: Double = 5.5
    private let junctionEvery = 22

    private var maze: CaveFlightMaze {
        CaveFlightMaze(
            segmentSpacing: segmentSpacing,
            junctionEvery: junctionEvery,
            openingLength: segmentSpacing * 3
        )
    }

    private var path3D: CaveFlightPath3D {
        CaveFlightPath3D(maze: maze)
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                drawTunnel(context: context, size: size)
            }
            .onChange(of: timeline.date) { _, newDate in
                if let start = startDate {
                    elapsed = newDate.timeIntervalSince(start)
                } else {
                    startDate = newDate
                }
            }
        }
    }

    private struct ProjectedSection {
        let tl: CGPoint
        let tr: CGPoint
        let bl: CGPoint
        let br: CGPoint
        let depth: Double
        let sampleDistance: Double
        let segmentIndex: Int
        let seedIndex: Int
    }

    private func drawTunnel(context: GraphicsContext, size: CGSize) {
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .color(Color(hue: 0.04, saturation: 0.24, brightness: ambientBrightness))
        )

        let cameraDistance = elapsed * speed
        let camera = path3D.pose(at: cameraDistance)
        let renderDistance = Double(sectionCount) * sectionStep
        let sections = buildMainSections(cameraDistance: cameraDistance, camera: camera, size: size)

        drawMainCorridor(context: context, sections: sections)
        drawJunctions(
            context: context,
            size: size,
            cameraDistance: cameraDistance,
            camera: camera,
            renderDistance: renderDistance
        )
        drawCrosshair(context: context, cx: size.width / 2, cy: size.height / 2)
    }

    private func buildMainSections(
        cameraDistance: Double,
        camera: CaveFlightPose,
        size: CGSize
    ) -> [ProjectedSection] {
        var sections: [ProjectedSection] = []
        let cameraSegment = path3D.segmentIndex(at: cameraDistance)
        var sampleDistance = sectionStep

        while sampleDistance <= Double(sectionCount) * sectionStep {
            let arcDistance = cameraDistance + sampleDistance
            let segmentIndex = path3D.segmentIndex(at: arcDistance)
            guard segmentIndex == cameraSegment else { break }
            let pose = path3D.pose(at: arcDistance)
            if let section = projectSection(
                pose: pose,
                camera: camera,
                size: size,
                sampleDistance: sampleDistance,
                seedDistance: arcDistance,
                segmentIndex: segmentIndex,
                seedIndex: Int(arcDistance.rounded())
            ) {
                sections.append(section)
            }
            sampleDistance += sectionStep
        }

        return sections
    }

    private func accentHue(for segmentIndex: Int) -> Double {
        let idx = Int(abs(noise1D(Double(segmentIndex) * 3.7 + 100)) * 997) % accentHues.count
        return accentHues[idx]
    }

    private func drawMainCorridor(context: GraphicsContext, sections: [ProjectedSection]) {
        guard sections.count >= 2 else { return }

        for index in stride(from: sections.count - 2, through: 0, by: -1) {
            let near = sections[index]
            let far = sections[index + 1]
            guard near.segmentIndex == far.segmentIndex else { continue }
            let hl = 1.0 / (1.0 + ((near.depth + far.depth) * 0.5) * 0.028)

            let ah = accentHue(for: near.segmentIndex)
            let litLeft = far.seedIndex % 5 == 0
            let litRight = far.seedIndex % 5 == 2

            // Ceiling — dark metallic
            fillQuad(context: context, far.tl, far.tr, near.tr, near.tl,
                     hue: 0.05, sat: 0.12, bright: max(0.14, 0.30 * hl))
            // Floor — darkest
            fillQuad(context: context, far.bl, far.br, near.br, near.bl,
                     hue: 0.07, sat: 0.10, bright: max(0.09, 0.20 * hl))
            // Left wall — gray metallic, accent light on some
            fillQuad(context: context, far.tl, far.bl, near.bl, near.tl,
                     hue: litLeft ? ah : 0.05,
                     sat: litLeft ? 0.55 : 0.16,
                     bright: litLeft ? max(0.35, 0.60 * hl) : max(0.15, 0.32 * hl))
            // Right wall
            fillQuad(context: context, far.tr, far.br, near.br, near.tr,
                     hue: litRight ? ah : 0.06,
                     sat: litRight ? 0.55 : 0.14,
                     bright: litRight ? max(0.35, 0.60 * hl) : max(0.15, 0.32 * hl))

            // Support rib (every 4th section) — thick structural beam
            let isRib = near.seedIndex % 4 == 0
            if isRib {
                let ribBright = max(0.20, 0.40 * hl)
                var ribPath = Path()
                ribPath.move(to: near.tl)
                ribPath.addLine(to: near.tr)
                ribPath.addLine(to: near.br)
                ribPath.addLine(to: near.bl)
                ribPath.closeSubpath()
                context.stroke(ribPath, with: .color(Color(hue: 0.06, saturation: 0.12, brightness: ribBright)),
                               lineWidth: 2.5)
            } else {
                strokeFrame(context: context, near.tl, near.tr, near.br, near.bl, alpha: max(0.05, hl * 0.15))
            }

            // Wall panel trim lines (1/3 and 2/3 height)
            let trimColor = Color(hue: 0.06, saturation: 0.10, brightness: max(0.09, 0.22 * hl))
            strokeLine(context: context, from: lerp(far.tl, far.bl, 0.33), to: lerp(near.tl, near.bl, 0.33),
                       color: trimColor, width: 0.5)
            strokeLine(context: context, from: lerp(far.tl, far.bl, 0.67), to: lerp(near.tl, near.bl, 0.67),
                       color: trimColor, width: 0.5)
            strokeLine(context: context, from: lerp(far.tr, far.br, 0.33), to: lerp(near.tr, near.br, 0.33),
                       color: trimColor, width: 0.5)
            strokeLine(context: context, from: lerp(far.tr, far.br, 0.67), to: lerp(near.tr, near.br, 0.67),
                       color: trimColor, width: 0.5)

            // Floor center stripe
            if near.seedIndex % 4 == 0 {
                let stripeColor = Color(hue: 0.12, saturation: 0.65,
                                        brightness: max(0.12, 0.30 * hl))
                strokeLine(context: context, from: midpoint(far.bl, far.br),
                           to: midpoint(near.bl, near.br), color: stripeColor, width: 1.5)
            }
        }
    }

    private func drawJunctions(
        context: GraphicsContext,
        size: CGSize,
        cameraDistance: Double,
        camera: CaveFlightPose,
        renderDistance: Double
    ) {
        let junctionIndex = max(0, Int(floor(cameraDistance / path3D.segmentLength)))
        let nodeArc = path3D.nodeDistance(at: junctionIndex)
        let sampleDistance = nodeArc - cameraDistance
        guard sampleDistance > 0.4 && sampleDistance < renderDistance else { return }

        let node = path3D.node(at: junctionIndex)
        guard let wallSection = projectSection(
            pose: node.incoming,
            camera: camera,
            size: size,
            sampleDistance: sampleDistance,
            seedDistance: nodeArc,
            segmentIndex: junctionIndex,
            seedIndex: junctionIndex * 17 + 5
        ) else { return }

        let hl = 1.0 / (1.0 + wallSection.depth * 0.02)

        for direction in node.junction.availableDirections {
            drawBranchShaft(
                context: context,
                camera: camera,
                size: size,
                node: node,
                nodeArc: nodeArc,
                direction: direction,
                sampleDistance: sampleDistance,
                chosen: direction == node.junction.chosenDirection,
                hl: hl
            )
        }

        drawPortalWall(context: context, section: wallSection, junction: node.junction, hl: hl)
    }

    private func drawPortalWall(
        context: GraphicsContext,
        section: ProjectedSection,
        junction: CaveFlightJunction,
        hl: Double
    ) {
        let openings = Set(junction.availableDirections)
        let leftOpen = openings.contains(.left)
        let rightOpen = openings.contains(.right)
        let upOpen = openings.contains(.up)
        let downOpen = openings.contains(.down)
        if !leftOpen {
            fillQuad(
                context: context,
                bilerp(section, u: 0.0, v: 0.0),
                bilerp(section, u: 0.32, v: 0.0),
                bilerp(section, u: 0.32, v: 1.0),
                bilerp(section, u: 0.0, v: 1.0),
                hue: 0.05, sat: 0.15,
                bright: max(0.14, 0.28 * hl)
            )
        }
        if !rightOpen {
            fillQuad(
                context: context,
                bilerp(section, u: 0.68, v: 0.0),
                bilerp(section, u: 1.0, v: 0.0),
                bilerp(section, u: 1.0, v: 1.0),
                bilerp(section, u: 0.68, v: 1.0),
                hue: 0.06, sat: 0.14,
                bright: max(0.14, 0.28 * hl)
            )
        }
        if !upOpen {
            fillQuad(
                context: context,
                bilerp(section, u: 0.0, v: 0.0),
                bilerp(section, u: 1.0, v: 0.0),
                bilerp(section, u: 1.0, v: 0.28),
                bilerp(section, u: 0.0, v: 0.28),
                hue: 0.05, sat: 0.12,
                bright: max(0.13, 0.26 * hl)
            )
        }
        if !downOpen {
            fillQuad(
                context: context,
                bilerp(section, u: 0.0, v: 0.72),
                bilerp(section, u: 1.0, v: 0.72),
                bilerp(section, u: 1.0, v: 1.0),
                bilerp(section, u: 0.0, v: 1.0),
                hue: 0.07, sat: 0.10,
                bright: max(0.12, 0.24 * hl)
            )
        }
        // Center pillar
        fillQuad(
            context: context,
            bilerp(section, u: 0.38, v: 0.38),
            bilerp(section, u: 0.62, v: 0.38),
            bilerp(section, u: 0.62, v: 0.62),
            bilerp(section, u: 0.38, v: 0.62),
            hue: 0.05, sat: 0.12,
            bright: max(0.16, 0.30 * hl)
        )

        strokeFrame(context: context, section.tl, section.tr, section.br, section.bl, alpha: max(0.15, hl * 0.40))
    }

    private func drawBranchShaft(
        context: GraphicsContext,
        camera: CaveFlightPose,
        size: CGSize,
        node: CaveFlightNode3D,
        nodeArc: Double,
        direction: CaveFlightDirection,
        sampleDistance: Double,
        chosen: Bool,
        hl: Double
    ) {
        let mouthPose = branchMouthPose(node: node, direction: direction)
        let endPose = CaveFlightPose(
            position: mouthPose.position + mouthPose.forward * (branchDepth * (chosen ? 2.0 : 0.95)),
            forward: mouthPose.forward,
            up: mouthPose.up
        )

        guard
            let mouthSection = projectSection(
                pose: mouthPose,
                camera: camera,
                size: size,
                sampleDistance: sampleDistance + 0.15,
                seedDistance: nodeArc + 0.15 + Double(direction.seedOffset) * 0.1,
                segmentIndex: -1,
                seedIndex: Int(sampleDistance * 10) + direction.seedOffset
            ),
            let endSection = projectSection(
                pose: endPose,
                camera: camera,
                size: size,
                sampleDistance: sampleDistance + branchDepth,
                seedDistance: nodeArc + branchDepth + Double(direction.seedOffset) * 0.1,
                segmentIndex: -1,
                seedIndex: Int(sampleDistance * 10) + direction.seedOffset + 7
            )
        else { return }

        let shaftHL = min(1.0, hl * (chosen ? 1.4 : 1.0))
        let cBright = chosen ? 0.28 : 0.15
        let fBright = chosen ? 0.50 : 0.25
        // Ceiling
        fillQuad(context: context, endSection.tl, endSection.tr, mouthSection.tr, mouthSection.tl,
                 hue: 0.05, sat: 0.12,
                 bright: max(cBright * 0.7, fBright * 0.8 * shaftHL))
        // Floor
        fillQuad(context: context, endSection.bl, endSection.br, mouthSection.br, mouthSection.bl,
                 hue: 0.07, sat: 0.10,
                 bright: max(cBright * 0.5, fBright * 0.6 * shaftHL))
        // Left wall
        fillQuad(context: context, endSection.tl, endSection.bl, mouthSection.bl, mouthSection.tl,
                 hue: 0.05, sat: chosen ? 0.18 : 0.12,
                 bright: max(cBright * 0.8, fBright * shaftHL))
        // Right wall
        fillQuad(context: context, endSection.tr, endSection.br, mouthSection.br, mouthSection.tr,
                 hue: 0.06, sat: chosen ? 0.18 : 0.12,
                 bright: max(cBright * 0.8, fBright * shaftHL))
        // Back wall
        if !chosen {
            fillQuad(context: context, endSection.tl, endSection.tr, endSection.br, endSection.bl,
                     hue: 0.05, sat: 0.10,
                     bright: max(0.06, 0.12 * shaftHL))
        } else {
            // Light at end of chosen path
            let ah = accentHue(for: path3D.segmentIndex(at: nodeArc) + 1)
            fillQuad(context: context, endSection.tl, endSection.tr, endSection.br, endSection.bl,
                     hue: ah, sat: 0.45,
                     bright: max(0.18, 0.35 * shaftHL))
        }
        strokeFrame(context: context, mouthSection.tl, mouthSection.tr, mouthSection.br, mouthSection.bl,
                    alpha: max(chosen ? 0.20 : 0.10, shaftHL * 0.35))
    }

    private func branchMouthPose(node: CaveFlightNode3D, direction: CaveFlightDirection) -> CaveFlightPose {
        let base = node.incoming.turned(direction)
        return CaveFlightPose(
            position: node.position + base.forward * 0.25,
            forward: base.forward,
            up: base.up
        )
    }

    private func projectSection(
        pose: CaveFlightPose,
        camera: CaveFlightPose,
        size: CGSize,
        sampleDistance: Double,
        seedDistance: Double,
        segmentIndex: Int,
        seedIndex: Int
    ) -> ProjectedSection? {
        let segShape = segmentIndex >= 0 ? abs(noise1D(Double(segmentIndex) * 4.2 + 500)) : 0.5
        let widthScale = 0.92 + segShape * 0.16
        let heightScale = 1.08 - segShape * 0.16
        let lw = (baseHalfW + noise1D(seedDistance * 0.4 + 10) * 0.3) * widthScale
        let rw = (baseHalfW + noise1D(seedDistance * 0.4 + 20) * 0.3) * widthScale
        let th = (baseHalfH + noise1D(seedDistance * 0.4 + 30) * 0.22) * heightScale
        let bh = (baseHalfH + noise1D(seedDistance * 0.4 + 40) * 0.22) * heightScale

        let right = pose.right
        let up = pose.up
        let tlWorld = pose.position + up * th - right * lw
        let trWorld = pose.position + up * th + right * rw
        let blWorld = pose.position - up * bh - right * lw
        let brWorld = pose.position - up * bh + right * rw

        guard
            let tl = project(world: tlWorld, camera: camera, size: size),
            let tr = project(world: trWorld, camera: camera, size: size),
            let bl = project(world: blWorld, camera: camera, size: size),
            let br = project(world: brWorld, camera: camera, size: size)
        else {
            return nil
        }

        let centerDepth = (pose.position - camera.position).dot(camera.forward)
        guard centerDepth > 0.2 else { return nil }

        return ProjectedSection(
            tl: tl,
            tr: tr,
            bl: bl,
            br: br,
            depth: centerDepth,
            sampleDistance: sampleDistance,
            segmentIndex: segmentIndex,
            seedIndex: seedIndex
        )
    }

    private func project(world: CaveFlightVector3, camera: CaveFlightPose, size: CGSize) -> CGPoint? {
        let relative = world - camera.position
        let viewX = relative.dot(camera.right)
        let viewY = relative.dot(camera.up)
        let viewZ = relative.dot(camera.forward)
        guard viewZ > 0.2 else { return nil }

        let scale = focalLength / viewZ
        return CGPoint(
            x: size.width / 2 + viewX * scale,
            y: size.height / 2 - viewY * scale
        )
    }

    private func fillQuad(
        context: GraphicsContext,
        _ p0: CGPoint,
        _ p1: CGPoint,
        _ p2: CGPoint,
        _ p3: CGPoint,
        hue: Double,
        sat: Double,
        bright: Double
    ) {
        var path = Path()
        path.move(to: p0)
        path.addLine(to: p1)
        path.addLine(to: p2)
        path.addLine(to: p3)
        path.closeSubpath()
        context.fill(
            path,
            with: .color(Color(hue: hue, saturation: sat, brightness: max(surfaceBrightnessFloor, min(0.95, bright))))
        )
    }

    private func strokeFrame(
        context: GraphicsContext,
        _ p0: CGPoint,
        _ p1: CGPoint,
        _ p2: CGPoint,
        _ p3: CGPoint,
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

    private func strokeLine(context: GraphicsContext, from: CGPoint, to: CGPoint, color: Color, width: Double) {
        var path = Path()
        path.move(to: from)
        path.addLine(to: to)
        context.stroke(path, with: .color(color), lineWidth: width)
    }

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

    private func midpoint(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        CGPoint(x: (a.x + b.x) * 0.5, y: (a.y + b.y) * 0.5)
    }

    private func lerp(_ a: CGPoint, _ b: CGPoint, _ t: Double) -> CGPoint {
        CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
    }

    private func bilerp(_ section: ProjectedSection, u: Double, v: Double) -> CGPoint {
        let top = lerp(section.tl, section.tr, u)
        let bottom = lerp(section.bl, section.br, u)
        return lerp(top, bottom, v)
    }

    private func average(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint, _ d: CGPoint) -> CGPoint {
        CGPoint(x: (a.x + b.x + c.x + d.x) * 0.25, y: (a.y + b.y + c.y + d.y) * 0.25)
    }

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

private extension CaveFlightDirection {
    var seedOffset: Int {
        switch self {
        case .left:
            return 11
        case .right:
            return 17
        case .up:
            return 23
        case .down:
            return 29
        }
    }
}
