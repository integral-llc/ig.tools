import Testing

@testable import IGTools

@Suite("Cave Flight Maze Tests")
struct CaveFlightMazeTests {
    private let maze = CaveFlightMaze(
        segmentSpacing: 2,
        junctionEvery: 6,
        openingLength: 6
    )

    @Test("Junction generation is deterministic and always exposes 2-4 exits")
    func junctionGenerationIsStable() {
        for index in 0..<64 {
            let first = maze.junction(at: index)
            let second = maze.junction(at: index)

            #expect(first == second)
            #expect((2...4).contains(first.availableDirections.count))
            #expect(Set(first.availableDirections).count == first.availableDirections.count)
            #expect(first.availableDirections.contains(first.chosenDirection))
        }
    }

    @Test("Openings are visible only inside the short junction throat")
    func openingsFollowOpeningWindow() {
        let junctionIndex = 5
        let junction = maze.junction(at: junctionIndex)
        let worldStart = Double(junctionIndex) * maze.junctionSpacing

        let visible = maze.openings(at: worldStart + 1)
        let hidden = maze.openings(at: worldStart + maze.openingLength + 0.1)

        #expect(visible.left == junction.availableDirections.contains(.left))
        #expect(visible.right == junction.availableDirections.contains(.right))
        #expect(visible.up == junction.availableDirections.contains(.up))
        #expect(visible.down == junction.availableDirections.contains(.down))
        #expect(hidden == .none)
    }

    @Test("Path delta across one full junction only turns during the throat")
    func pathDeltaMatchesChosenExit() {
        for junctionIndex in 0..<32 {
            let junction = maze.junction(at: junctionIndex)
            let start = Double(junctionIndex) * maze.junctionSpacing
            let delta = maze.pathDelta(from: start, to: start + maze.junctionSpacing)

            #expect(abs(delta.x - junction.chosenDirection.xSlope * maze.openingLength) < 0.000_001)
            #expect(abs(delta.y - junction.chosenDirection.ySlope * maze.openingLength) < 0.000_001)
        }
    }

    @Test("Maze samples cover all turn directions")
    func mazeUsesAllDirections() {
        let directions = Set((0..<128).map { maze.junction(at: $0).chosenDirection })
        #expect(directions.contains(.left))
        #expect(directions.contains(.right))
        #expect(directions.contains(.up))
        #expect(directions.contains(.down))
    }
}
