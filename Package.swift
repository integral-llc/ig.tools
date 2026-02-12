// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "IGTools",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "IGTools",
            dependencies: ["KeyboardShortcuts"],
            path: "Sources"
        ),
        .testTarget(
            name: "IGToolsTests",
            dependencies: ["IGTools"],
            path: "Tests"
        ),
    ]
)
