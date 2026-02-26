import SwiftUI

struct TextShortcutsTool: Tool {
    let id = "textShortcuts"
    let name = "Text Shortcuts"
    let icon = "text.cursor"

    private let state: TextShortcutsState

    init(state: TextShortcutsState) {
        self.state = state
    }

    var opacity: Double { state.opacity }
    var alwaysOnTop: Bool { state.alwaysOnTop }
    var defaultSize: CGSize? { CGSize(width: 600, height: 440) }

    @MainActor
    func makeView() -> AnyView {
        AnyView(TextShortcutsView(state: state))
    }

    @MainActor
    func makeSettingsView() -> AnyView {
        AnyView(TextShortcutsSettingsView(state: state))
    }
}
