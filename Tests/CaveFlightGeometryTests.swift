import Testing

@testable import IGTools

@Suite("Cave Flight Geometry Tests")
struct CaveFlightGeometryTests {
    private let maze = CaveFlightMaze(
        segmentSpacing: 2,
        junctionEvery: 6,
        openingLength: 6
    )

    @Test("Relative turns stay orthogonal")
    func relativeTurnsStayOrthogonal() {
        let start = CaveFlightPose(
            position: .zero,
            forward: CaveFlightVector3(x: 0, y: 0, z: 1),
            up: CaveFlightVector3(x: 0, y: 1, z: 0)
        )

        let left = start.turned(.left)
        let right = start.turned(.right)
        let up = start.turned(.up)
        let down = start.turned(.down)

        #expect(left.forward == CaveFlightVector3(x: -1, y: 0, z: 0))
        #expect(right.forward == CaveFlightVector3(x: 1, y: 0, z: 0))
        #expect(up.forward == CaveFlightVector3(x: 0, y: 1, z: 0))
        #expect(down.forward == CaveFlightVector3(x: 0, y: -1, z: 0))
        #expect(left.right.dot(left.forward) == 0)
        #expect(up.right.dot(up.forward) == 0)
    }

    @Test("Every junction changes heading by 90 degrees")
    func everyJunctionChangesHeading() {
        let path = CaveFlightPath3D(maze: maze)

        for index in 0..<32 {
            let node = path.node(at: index)
            #expect(node.incoming.forward.dot(node.outgoing.forward) == 0)
        }
    }
}
