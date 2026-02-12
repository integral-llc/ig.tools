import SwiftUI

/// Strategy pattern: each utility conforms to Tool and provides its own view + state.
protocol Tool: Identifiable, Sendable {
    var id: String { get }
    var name: String { get }
    var icon: String { get } // SF Symbol name

    /// Current window opacity (0.0–1.0).
    @MainActor var opacity: Double { get }
    /// Whether the tool window floats above all other windows.
    @MainActor var alwaysOnTop: Bool { get }

    @MainActor
    func makeView() -> AnyView

    @MainActor
    func makeSettingsView() -> AnyView
}
