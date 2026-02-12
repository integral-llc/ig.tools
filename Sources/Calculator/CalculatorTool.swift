import SwiftUI

/// Tool conformance for the Calculator — Strategy pattern.
struct CalculatorTool: Tool {
    let id = "calculator"
    let name = "Calculator"
    let icon = "function"

    private let state: CalculatorState

    init(state: CalculatorState) {
        self.state = state
    }

    var opacity: Double { state.opacity }
    var alwaysOnTop: Bool { state.alwaysOnTop }

    @MainActor
    func makeView() -> AnyView {
        AnyView(CalculatorView(state: state))
    }

    @MainActor
    func makeSettingsView() -> AnyView {
        AnyView(CalculatorSettingsView(state: state))
    }
}
