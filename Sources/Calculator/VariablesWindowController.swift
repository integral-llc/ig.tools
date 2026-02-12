import AppKit
import SwiftUI

/// Manages a standalone NSWindow for the variables editor.
@MainActor
final class VariablesWindowController {
    static let shared = VariablesWindowController()

    static let windowID = "variables"
    private var window: NSWindow?
    private var delegate: VariablesWindowDelegate?

    func show(state: CalculatorState) {
        if let existing = window, existing.isVisible {
            NSApp.activate(ignoringOtherApps: true)
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let view = VariablesView(state: state)
        let hostingView = NSHostingView(rootView: view)

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        win.title = "Variables"
        win.contentView = hostingView
        win.isReleasedWhenClosed = false

        let del = VariablesWindowDelegate()
        win.delegate = del
        self.delegate = del

        ToolWindowManager.restoreFrame(for: win, id: Self.windowID)
        NSApp.activate(ignoringOtherApps: true)
        win.makeKeyAndOrderFront(nil)

        self.window = win
    }
}

private final class VariablesWindowDelegate: NSObject, NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        ToolWindowManager.saveFrame(for: VariablesWindowController.windowID, frame: window.frame)
    }
}
