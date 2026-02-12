import AppKit
import SwiftUI

/// Persisted window frame.
struct SavedFrame: Codable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    var nsRect: NSRect {
        NSRect(x: x, y: y, width: width, height: height)
    }

    init(_ rect: NSRect) {
        self.x = rect.origin.x
        self.y = rect.origin.y
        self.width = rect.size.width
        self.height = rect.size.height
    }
}

/// Manages a floating NSWindow for each tool, keyed by tool ID.
@MainActor
final class ToolWindowManager {
    static let shared = ToolWindowManager()
    private init() {}

    private var windows: [String: NSWindow] = [:]

    func toggleWindow(for tool: any Tool) {
        if let window = windows[tool.id], window.isVisible {
            window.close()
        } else {
            showWindow(for: tool)
        }
    }

    private func showWindow(for tool: any Tool) {
        if let existing = windows[tool.id] {
            existing.makeKeyAndOrderFront(nil)
            applySettings(existing, tool: tool)
            return
        }

        let contentView = ToolWindowContentView(tool: tool)
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.setFrameSize(hostingView.fittingSize)

        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 440),
            styleMask: [.titled, .closable, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        window.title = tool.name
        window.contentView = hostingView
        window.isReleasedWhenClosed = false
        window.isMovableByWindowBackground = true

        let delegate = ToolWindowDelegate(toolID: tool.id)
        window.delegate = delegate
        objc_setAssociatedObject(window, &associatedDelegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        Self.restoreFrame(for: window, id: tool.id)
        applySettings(window, tool: tool)
        windows[tool.id] = window
        window.makeKeyAndOrderFront(nil)

        observeSettings(for: tool)
    }

    // MARK: - Frame persistence (shared helpers)

    static func restoreFrame(for window: NSWindow, id: String) {
        let repo = Repository<SavedFrame>(key: "window.frame.\(id)")
        guard let saved = repo.load() else {
            window.center()
            return
        }

        let savedRect = saved.nsRect
        let fitsAnyScreen = NSScreen.screens.contains { screen in
            screen.visibleFrame.intersects(savedRect)
        }

        if fitsAnyScreen {
            window.setFrame(savedRect, display: true)
        } else {
            positionTopRight(window)
        }
    }

    static func saveFrame(for id: String, frame: NSRect) {
        let repo = Repository<SavedFrame>(key: "window.frame.\(id)")
        repo.save(SavedFrame(frame))
    }

    private static func positionTopRight(_ window: NSWindow) {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else {
            window.center()
            return
        }
        let visible = screen.visibleFrame
        let size = window.frame.size
        let x = visible.maxX - size.width - 12
        let y = visible.maxY - size.height - 12
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }

    // MARK: - Window settings

    private func applySettings(_ window: NSWindow, tool: any Tool) {
        window.alphaValue = tool.opacity
        window.level = tool.alwaysOnTop ? .floating : .normal
    }

    private func observeSettings(for tool: any Tool) {
        withObservationTracking {
            _ = tool.opacity
            _ = tool.alwaysOnTop
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self, let window = self.windows[tool.id], window.isVisible else { return }
                self.applySettings(window, tool: tool)
                self.observeSettings(for: tool)
            }
        }
    }

    func closeAll() {
        windows.values.forEach { $0.close() }
    }
}

private nonisolated(unsafe) var associatedDelegateKey: UInt8 = 0

// MARK: - Window Delegate

private final class ToolWindowDelegate: NSObject, NSWindowDelegate, @unchecked Sendable {
    let toolID: String

    init(toolID: String) {
        self.toolID = toolID
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        ToolWindowManager.saveFrame(for: toolID, frame: window.frame)
    }
}
