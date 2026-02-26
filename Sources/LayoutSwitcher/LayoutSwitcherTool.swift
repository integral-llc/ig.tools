import SwiftUI

struct LayoutSwitcherTool: Tool {
    let id = "layoutSwitcher"
    let name = "Layout Switcher"
    let icon = "keyboard"

    private let state: LayoutSwitcherState

    init(state: LayoutSwitcherState) {
        self.state = state
    }

    var opacity: Double { state.opacity }
    var alwaysOnTop: Bool { state.alwaysOnTop }
    var defaultSize: CGSize? { CGSize(width: 320, height: 360) }

    @MainActor
    func makeView() -> AnyView {
        AnyView(LayoutSwitcherView(state: state))
    }

    @MainActor
    func makeSettingsView() -> AnyView {
        AnyView(LayoutSwitcherSettingsView(state: state))
    }
}
