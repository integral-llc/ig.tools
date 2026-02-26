import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let registry = ToolRegistry()
    let calcState = CalculatorState()
    let textShortcutsState = TextShortcutsState()
    let layoutSwitcherState = LayoutSwitcherState()
    private var accessibilityPanel: NSPanel?
    private(set) var aboutPanelOptions: [NSApplication.AboutPanelOptionKey: Any] = [:]

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        registry.register(CalculatorTool(state: calcState))
        registry.register(TextShortcutsTool(state: textShortcutsState))
        registry.register(LayoutSwitcherTool(state: layoutSwitcherState))

        // Prompt for accessibility permissions if not yet granted
        if !KeystrokeMonitor.isAccessibilityGranted() {
            showAccessibilityPrompt()
        }

        // Prepare About panel options (shown later when user clicks "About")
        if let infoDict = Bundle.main.infoDictionary {
            let version = infoDict["CFBundleShortVersionString"] as? String ?? "Unknown"
            let build = infoDict["CFBundleVersion"] as? String ?? "Unknown"

            let appIcon = NSImage(named: "AppIcon")
                ?? NSApp.applicationIconImage
                ?? NSImage(systemSymbolName: "function", accessibilityDescription: nil)
                ?? NSImage()

            aboutPanelOptions = [
                .applicationVersion: "Version \(version) (\(build))",
                .applicationName: "IG Tools",
                .applicationIcon: appIcon
            ]
        }
    }

    private func showAccessibilityPrompt() {
        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        panel.title = "IG Tools"
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.level = .statusBar

        let view = AccessibilityPromptView(state: textShortcutsState) { [weak self] in
            self?.accessibilityPanel?.close()
            self?.accessibilityPanel = nil
        }
        let hostingView = NSHostingView(rootView: view)
        hostingView.setFrameSize(hostingView.fittingSize)
        panel.contentView = hostingView
        panel.setContentSize(hostingView.fittingSize)
        panel.center()

        self.accessibilityPanel = panel
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
