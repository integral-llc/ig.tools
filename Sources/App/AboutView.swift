import SwiftUI

struct AboutView: View {
    let appIcon: NSImage
    let appName: String
    let version: String

    @State private var cloth = ClothState(
        columns: 15,
        rows: 12,
        spacing: 12,
        origin: SIMD2(10, 10)
    )

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            infoColumn
            Divider()
            ClothView(cloth: cloth)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
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
}
