import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let registry = ToolRegistry()
    let calcState = CalculatorState()
    let textShortcutsState = TextShortcutsState()
    private var accessibilityPanel: NSPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        registry.register(CalculatorTool(state: calcState))
        registry.register(TextShortcutsTool(state: textShortcutsState))

        // Prompt for accessibility permissions if not yet granted
        if !KeystrokeMonitor.isAccessibilityGranted() {
            showAccessibilityPrompt()
        }

        // Customize the About panel
        if let infoDict = Bundle.main.infoDictionary {
            let version = infoDict["CFBundleShortVersionString"] as? String ?? "Unknown"
            let build = infoDict["CFBundleVersion"] as? String ?? "Unknown"

            // Try to load the AppIcon from assets, fallback to system symbol
            var appIcon = NSImage(named: "AppIcon")
            
            // If that didn't work, try to get the application icon directly
            if appIcon == nil {
                appIcon = NSApp.applicationIconImage
            }
            
            // If still no icon, use the system symbol
            if appIcon == nil {
                appIcon = NSImage(systemSymbolName: "function", accessibilityDescription: nil)
            }
            
            // Final fallback to a generic image
            if appIcon == nil {
                appIcon = NSImage()
            }

            NSApp.orderFrontStandardAboutPanel(
                options: [
                    NSApplication.AboutPanelOptionKey.applicationVersion: "Version \(version) (\(build))",
                    NSApplication.AboutPanelOptionKey.applicationName: "IG Tools",
                    NSApplication.AboutPanelOptionKey.applicationIcon: appIcon ?? NSImage()
                ]
            )
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
        panel.level = .floating

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
