import Foundation

enum CaveFlightDirection: CaseIterable, Sendable {
    case left
    case right
    case up
    case down

    var xSlope: Double {
        switch self {
        case .left:
            return -1.05
        case .right:
            return 1.05
        case .up, .down:
            return 0
        }
    }

    var ySlope: Double {
        switch self {
        case .up:
            return -0.78
        case .down:
            return 0.78
        case .left, .right:
            return 0
        }
    }

    fileprivate var salt: UInt64 {
        switch self {
        case .left:
            return 0x9E37_79B1
        case .right:
            return 0x85EB_CA77
        case .up:
            return 0xC2B2_AE3D
        case .down:
            return 0x27D4_EB2F
        }
    }
}

struct CaveFlightJunction: Equatable, Sendable {
    let availableDirections: [CaveFlightDirection]
    let chosenDirection: CaveFlightDirection
}

struct CaveFlightOpenings: Equatable, Sendable {
    let left: Bool
    let right: Bool
    let up: Bool
    let down: Bool

    static let none = CaveFlightOpenings(left: false, right: false, up: false, down: false)
}

struct CaveFlightMaze: Sendable {
    let segmentSpacing: Double
    let junctionEvery: Int
    let openingLength: Double

    var junctionSpacing: Double {
        Double(junctionEvery) * segmentSpacing
    }

    func junction(at index: Int) -> CaveFlightJunction {
        let directions = CaveFlightDirection.allCases
            .map { direction in
                (direction, hash(index, salt: direction.salt))
            }
            .sorted { $0.1 < $1.1 }
            .map(\.0)

        let branchCount = 2 + Int(hash(index, salt: 0xD1B5_4A32) % 3)
        let availableDirections = Array(directions.prefix(branchCount))
        let chosenIndex = Int(hash(index, salt: 0x94D0_49BB) % UInt64(availableDirections.count))

        return CaveFlightJunction(
            availableDirections: availableDirections,
            chosenDirection: availableDirections[chosenIndex]
        )
    }

    func openings(at worldZ: Double) -> CaveFlightOpenings {
        guard let activeJunction = activeJunction(at: worldZ) else { return .none }

        let directions = Set(activeJunction.junction.availableDirections)
        return CaveFlightOpenings(
            left: directions.contains(.left),
            right: directions.contains(.right),
            up: directions.contains(.up),
            down: directions.contains(.down)
        )
    }

    func chosenDirection(at worldZ: Double) -> CaveFlightDirection? {
        activeJunction(at: worldZ)?.junction.chosenDirection
    }

    func pathDelta(from z0: Double, to z1: Double) -> (x: Double, y: Double) {
        guard z1 > z0 else { return (0, 0) }

        var x: Double = 0
        var y: Double = 0
        let j0 = max(0, Int(floor(z0 / junctionSpacing)))
        let j1 = max(0, Int(floor(z1 / junctionSpacing)))

        for junctionIndex in j0...j1 {
            let start = max(z0, Double(junctionIndex) * junctionSpacing)
            let end = min(z1, Double(junctionIndex + 1) * junctionSpacing)
            guard end > start else { continue }

            let chosen = junction(at: junctionIndex).chosenDirection
            let turnEnd = min(end, Double(junctionIndex) * junctionSpacing + openingLength)
            let span = max(0, turnEnd - start)
            guard span > 0 else { continue }
            x += chosen.xSlope * span
            y += chosen.ySlope * span
        }

        return (x, y)
    }

    private func activeJunction(at worldZ: Double) -> (index: Int, localZ: Double, junction: CaveFlightJunction)? {
        guard worldZ >= 0 else { return nil }

        let junctionIndex = Int(floor(worldZ / junctionSpacing))
        let localZ = worldZ - Double(junctionIndex) * junctionSpacing
        guard localZ >= 0 && localZ < openingLength else { return nil }
        return (junctionIndex, localZ, junction(at: junctionIndex))
    }

    private func hash(_ index: Int, salt: UInt64) -> UInt64 {
        var value = UInt64(bitPattern: Int64(index)) &+ salt &+ 0x9E37_79B9_7F4A_7C15
        value ^= value >> 30
        value &*= 0xBF58_476D_1CE4_E5B9
        value ^= value >> 27
        value &*= 0x94D0_49BB_1331_11EB
        value ^= value >> 31
        return value
    }
}
