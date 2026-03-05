import Foundation
import simd

// MARK: - Data types

struct Particle: Sendable {
    var position: SIMD2<Float>
    var previousPosition: SIMD2<Float>
    var isPinned: Bool

    init(x: Float, y: Float, pinned: Bool = false) {
        self.position = SIMD2(x, y)
        self.previousPosition = SIMD2(x, y)
        self.isPinned = pinned
    }
}

struct Constraint: Sendable {
    let indexA: Int
    let indexB: Int
    let restLength: Float
}

// MARK: - Cloth simulation state

@Observable
@MainActor
final class ClothState {
    private(set) var particles: [Particle]
    let constraints: [Constraint]
    let columns: Int
    let rows: Int

    var draggedParticleIndex: Int?

    private let gravity: SIMD2<Float> = SIMD2(0, 980)
    private let damping: Float = 0.99
    private let constraintIterations: Int = 5

    init(columns: Int, rows: Int, spacing: Float, origin: SIMD2<Float>) {
        self.columns = columns
        self.rows = rows

        // Build particle grid — top row is pinned
        var builtParticles: [Particle] = []
        builtParticles.reserveCapacity(columns * rows)
        for row in 0..<rows {
            for col in 0..<columns {
                let x = origin.x + Float(col) * spacing
                let y = origin.y + Float(row) * spacing
                builtParticles.append(Particle(x: x, y: y, pinned: row == 0))
            }
        }
        self.particles = builtParticles

        // Build constraints: structural (horizontal + vertical) + shear (diagonal)
        var builtConstraints: [Constraint] = []
        let diagonalLength = spacing * sqrt(2)
        for row in 0..<rows {
            for col in 0..<columns {
                let idx = row * columns + col
                // Horizontal
                if col < columns - 1 {
                    builtConstraints.append(Constraint(indexA: idx, indexB: idx + 1, restLength: spacing))
                }
                // Vertical
                if row < rows - 1 {
                    builtConstraints.append(Constraint(indexA: idx, indexB: idx + columns, restLength: spacing))
                }
                // Shear diagonals
                if col < columns - 1 && row < rows - 1 {
                    builtConstraints.append(Constraint(
                        indexA: idx, indexB: idx + columns + 1, restLength: diagonalLength
                    ))
                    builtConstraints.append(Constraint(
                        indexA: idx + 1, indexB: idx + columns, restLength: diagonalLength
                    ))
                }
            }
        }
        self.constraints = builtConstraints
    }

    // MARK: - Physics step

    func update(dt: Float) {
        // Verlet integration
        for i in particles.indices where !particles[i].isPinned {
            let velocity = (particles[i].position - particles[i].previousPosition) * damping
            particles[i].previousPosition = particles[i].position
            particles[i].position = particles[i].position + velocity + gravity * (dt * dt)
        }

        // Constraint satisfaction (iterative relaxation)
        for _ in 0..<constraintIterations {
            for c in constraints {
                let delta = particles[c.indexB].position - particles[c.indexA].position
                let distance = simd_length(delta)
                guard distance > 0 else { continue }
                let diff = (distance - c.restLength) / distance
                let correction = delta * 0.5 * diff

                if !particles[c.indexA].isPinned {
                    particles[c.indexA].position += correction
                }
                if !particles[c.indexB].isPinned {
                    particles[c.indexB].position -= correction
                }
            }
        }
    }

    // MARK: - Interaction

    func nearestParticle(to point: SIMD2<Float>, within radius: Float) -> Int? {
        var bestIndex: Int?
        var bestDistance: Float = radius
        for i in particles.indices {
            let d = simd_length(particles[i].position - point)
            if d < bestDistance {
                bestDistance = d
                bestIndex = i
            }
        }
        return bestIndex
    }

    func moveParticle(at index: Int, to position: SIMD2<Float>) {
        particles[index].position = position
        particles[index].previousPosition = position
    }
}
