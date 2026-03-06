import Foundation

struct CaveFlightVector3: Equatable, Sendable {
    var x: Double
    var y: Double
    var z: Double

    static let zero = CaveFlightVector3(x: 0, y: 0, z: 0)

    static func + (lhs: Self, rhs: Self) -> Self {
        Self(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }

    static func - (lhs: Self, rhs: Self) -> Self {
        Self(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
    }

    static func * (lhs: Self, rhs: Double) -> Self {
        Self(x: lhs.x * rhs, y: lhs.y * rhs, z: lhs.z * rhs)
    }

    func dot(_ other: Self) -> Double {
        x * other.x + y * other.y + z * other.z
    }

    func cross(_ other: Self) -> Self {
        Self(
            x: y * other.z - z * other.y,
            y: z * other.x - x * other.z,
            z: x * other.y - y * other.x
        )
    }
}

struct CaveFlightPose: Equatable, Sendable {
    var position: CaveFlightVector3
    var forward: CaveFlightVector3
    var up: CaveFlightVector3

    var right: CaveFlightVector3 {
        up.cross(forward)
    }

    func turned(_ direction: CaveFlightDirection) -> Self {
        switch direction {
        case .left:
            return Self(position: position, forward: right * -1, up: up)
        case .right:
            return Self(position: position, forward: right, up: up)
        case .up:
            return Self(position: position, forward: up, up: forward * -1)
        case .down:
            return Self(position: position, forward: up * -1, up: forward)
        }
    }
}

struct CaveFlightNode3D: Sendable {
    let position: CaveFlightVector3
    let incoming: CaveFlightPose
    let outgoing: CaveFlightPose
    let junction: CaveFlightJunction
}

struct CaveFlightPath3D: Sendable {
    let maze: CaveFlightMaze

    var segmentLength: Double {
        maze.junctionSpacing
    }

    func segmentIndex(at distance: Double) -> Int {
        max(0, Int(floor(distance / segmentLength)))
    }

    func nodeDistance(at index: Int) -> Double {
        Double(index + 1) * segmentLength
    }

    func pose(at distance: Double) -> CaveFlightPose {
        guard distance > 0 else { return initialPose }

        var pose = initialPose
        var remaining = distance
        var junctionIndex = 0

        while remaining > segmentLength {
            pose.position = pose.position + pose.forward * segmentLength
            pose = pose.turned(maze.junction(at: junctionIndex).chosenDirection)
            remaining -= segmentLength
            junctionIndex += 1
        }

        pose.position = pose.position + pose.forward * remaining
        return pose
    }

    func node(at index: Int) -> CaveFlightNode3D {
        var pose = initialPose
        if index > 0 {
            for junctionIndex in 0..<index {
                pose.position = pose.position + pose.forward * segmentLength
                pose = pose.turned(maze.junction(at: junctionIndex).chosenDirection)
            }
        }

        let junction = maze.junction(at: index)
        let nodePosition = pose.position + pose.forward * segmentLength
        let incoming = CaveFlightPose(position: nodePosition, forward: pose.forward, up: pose.up)
        let outgoing = incoming.turned(junction.chosenDirection)

        return CaveFlightNode3D(
            position: nodePosition,
            incoming: incoming,
            outgoing: outgoing,
            junction: junction
        )
    }

    func branchPose(at index: Int, direction: CaveFlightDirection) -> CaveFlightPose {
        node(at: index).incoming.turned(direction)
    }

    private var initialPose: CaveFlightPose {
        CaveFlightPose(
            position: .zero,
            forward: CaveFlightVector3(x: 0, y: 0, z: 1),
            up: CaveFlightVector3(x: 0, y: 1, z: 0)
        )
    }
}
