import AppKit
import SwiftUI

@MainActor
final class AboutWindow {
    static let shared = AboutWindow()
    private init() {}

    private var panel: NSPanel?

    func show(appIcon: NSImage, appName: String, version: String) {
        if let existing = panel, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = AboutView(appIcon: appIcon, appName: appName, version: version)
        let hostingView = NSHostingView(rootView: view)
        hostingView.setFrameSize(hostingView.fittingSize)

        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        panel.title = "About \(appName)"
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.contentView = hostingView
        panel.setContentSize(hostingView.fittingSize)
        panel.center()

        self.panel = panel
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
