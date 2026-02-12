import SwiftUI

/// Factory + Registry: discovers, stores, and provides tools by id.
@Observable
@MainActor
final class ToolRegistry {
    private(set) var tools: [any Tool] = []

    func register(_ tool: any Tool) {
        tools.append(tool)
    }

    func tool(for id: String) -> (any Tool)? {
        tools.first { $0.id == id }
    }
}
