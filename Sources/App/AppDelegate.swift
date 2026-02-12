import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let registry = ToolRegistry()
    let calcState = CalculatorState()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        registry.register(CalculatorTool(state: calcState))
    }
}
