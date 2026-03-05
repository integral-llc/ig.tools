import Testing
import simd

@testable import IGTools

@Suite("Cloth Simulator Tests")
struct ClothSimulatorTests {

    // MARK: - Grid initialization

    @Test("Creates correct number of particles")
    @MainActor func particleCount() {
        let cloth = ClothState(columns: 5, rows: 4, spacing: 10, origin: SIMD2(0, 0))
        #expect(cloth.particles.count == 20)
    }

    @Test("Top row particles are pinned, rest are free")
    @MainActor func topRowPinned() {
        let cloth = ClothState(columns: 5, rows: 4, spacing: 10, origin: SIMD2(0, 0))
        for col in 0..<5 {
            #expect(cloth.particles[col].isPinned, "Top row particle \(col) should be pinned")
        }
        for i in 5..<20 {
            #expect(!cloth.particles[i].isPinned, "Particle \(i) should not be pinned")
        }
    }

    @Test("Particles have correct initial positions")
    @MainActor func initialPositions() {
        let origin = SIMD2<Float>(10, 20)
        let cloth = ClothState(columns: 3, rows: 2, spacing: 15, origin: origin)

        #expect(cloth.particles[0].position == SIMD2(10, 20))
        #expect(cloth.particles[1].position == SIMD2(25, 20))
        #expect(cloth.particles[2].position == SIMD2(40, 20))
        #expect(cloth.particles[3].position == SIMD2(10, 35))
        #expect(cloth.particles[4].position == SIMD2(25, 35))
        #expect(cloth.particles[5].position == SIMD2(40, 35))
    }

    // MARK: - Constraint setup

    @Test("Correct number of constraints for a grid")
    @MainActor func constraintCount() {
        let cols = 5
        let rows = 4
        let cloth = ClothState(columns: cols, rows: rows, spacing: 10, origin: SIMD2(0, 0))

        let horizontal = rows * (cols - 1)              // 16
        let vertical = (rows - 1) * cols               // 15
        let expected = horizontal + vertical           // 31 (structural only, no shear)

        #expect(cloth.constraints.count == expected)
    }

    // MARK: - Physics simulation

    @Test("Gravity moves free particles downward")
    @MainActor func gravityEffect() {
        let cloth = ClothState(columns: 3, rows: 3, spacing: 20, origin: SIMD2(0, 0))
        let initialY = cloth.particles[4].position.y // center particle, row 1

        for _ in 0..<10 {
            cloth.update(dt: 1.0 / 60.0)
        }

        #expect(cloth.particles[4].position.y > initialY,
                "Free particle should move down under gravity")
    }

    @Test("Pinned particles stay fixed after simulation")
    @MainActor func pinnedStayFixed() {
        let cloth = ClothState(columns: 4, rows: 3, spacing: 15, origin: SIMD2(5, 5))
        let pinnedPositions = (0..<4).map { cloth.particles[$0].position }

        for _ in 0..<20 {
            cloth.update(dt: 1.0 / 60.0)
        }

        for i in 0..<4 {
            #expect(cloth.particles[i].position == pinnedPositions[i],
                    "Pinned particle \(i) should not move")
        }
    }

    @Test("Constraints prevent excessive stretching")
    @MainActor func constraintSatisfaction() {
        let spacing: Float = 15
        let cloth = ClothState(columns: 5, rows: 5, spacing: spacing, origin: SIMD2(0, 0))

        for _ in 0..<30 {
            cloth.update(dt: 1.0 / 60.0)
        }

        let tolerance: Float = 1.5
        for c in cloth.constraints {
            let dist = simd_length(cloth.particles[c.indexB].position - cloth.particles[c.indexA].position)
            #expect(dist < c.restLength * tolerance,
                    "Constraint (\(c.indexA)-\(c.indexB)) stretched to \(dist), limit \(c.restLength * tolerance)")
        }
    }

    // MARK: - Interaction

    @Test("Finds nearest particle within radius")
    @MainActor func nearestParticleHit() {
        let cloth = ClothState(columns: 3, rows: 3, spacing: 20, origin: SIMD2(0, 0))
        // Particle at index 4 is at (20, 20) — center of grid
        let idx = cloth.nearestParticle(to: SIMD2(22, 18), within: 10)
        #expect(idx == 4)
    }

    @Test("Returns nil when no particle within radius")
    @MainActor func nearestParticleMiss() {
        let cloth = ClothState(columns: 3, rows: 3, spacing: 20, origin: SIMD2(0, 0))
        let idx = cloth.nearestParticle(to: SIMD2(100, 100), within: 5)
        #expect(idx == nil)
    }

    @Test("Drag sets position and zeros velocity")
    @MainActor func dragInteraction() {
        let cloth = ClothState(columns: 3, rows: 3, spacing: 20, origin: SIMD2(0, 0))
        let target = SIMD2<Float>(50, 50)
        cloth.moveParticle(at: 4, to: target)

        #expect(cloth.particles[4].position == target)
        #expect(cloth.particles[4].previousPosition == target,
                "Previous position should match to zero velocity")
    }
}
