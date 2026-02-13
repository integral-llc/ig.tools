import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let registry = ToolRegistry()
    let calcState = CalculatorState()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        registry.register(CalculatorTool(state: calcState))

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
}
