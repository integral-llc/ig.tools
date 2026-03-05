import SwiftUI

enum AboutEffect: Int, CaseIterable {
    case cloth
    case blob
    case constellation
    case sineWave
    case dnaHelix
    case fractalTree
    case caveFlight
    case rubiksCube

    var label: String {
        switch self {
        case .cloth: "Cloth"
        case .blob: "Blob"
        case .constellation: "Constellation"
        case .sineWave: "Sine Wave"
        case .dnaHelix: "DNA Helix"
        case .fractalTree: "Fractal Tree"
        case .caveFlight: "Cave Flight"
        case .rubiksCube: "Rubik's Cube"
        }
    }
}

struct AboutView: View {
    let appIcon: NSImage
    let appName: String
    let version: String

    @State private var effect: AboutEffect = .cloth
    @State private var cloth = ClothState(
        columns: 14,
        rows: 25,
        spacing: 14,
        origin: SIMD2(8, 8)
    )

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            infoColumn
            Divider()
            effectPanel
        }
        .frame(width: 375, height: 375)
    }

    private var infoColumn: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(nsImage: appIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64)

            Text(appName)
                .font(.title2)
                .fontWeight(.semibold)

            Text(version)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text("\u{00A9} 2025 IG")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(20)
        .frame(width: 150)
    }

    private var effectPanel: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                switch effect {
                case .cloth:
                    ClothView(cloth: cloth)
                case .blob:
                    MorphingBlobView()
                case .constellation:
                    ParticleConstellationView()
                case .sineWave:
                    SineWaveInkBleedView()
                case .dnaHelix:
                    DNAHelixView()
                case .fractalTree:
                    FractalTreeView()
                case .caveFlight:
                    CaveFlightView()
                case .rubiksCube:
                    RubiksCubeView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            effectSwitcher
                .padding(8)
        }
    }

    private var effectSwitcher: some View {
        HStack(spacing: 2) {
            Button {
                switchEffect(delta: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 9, weight: .semibold))
                    .frame(width: 18, height: 18)
            }

            Button {
                switchEffect(delta: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .frame(width: 18, height: 18)
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 5))
    }

    private func switchEffect(delta: Int) {
        let cases = AboutEffect.allCases
        let idx = (effect.rawValue + delta + cases.count) % cases.count
        effect = cases[idx]
    }
}
