import Foundation

/// Common window-level settings every tool can expose.
protocol ToolSettings: Codable, Sendable {
    var opacity: Double { get set }
    var alwaysOnTop: Bool { get set }
}
