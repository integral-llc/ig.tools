import SwiftUI

/// Observable state for the Text Shortcuts tool.
@Observable
@MainActor
final class TextShortcutsState {
    var shortcuts: [TextShortcut] = [] {
        didSet { persistShortcuts(); scheduleMonitorUpdate() }
    }

    var isEnabled: Bool = false {
        didSet { persistEnabled(); scheduleMonitorUpdate() }
    }

    var isAccessibilityGranted: Bool = false

    // MARK: - Window settings

    var opacity: Double {
        didSet { persistSettings() }
    }

    var alwaysOnTop: Bool {
        didSet { persistSettings() }
    }

    // MARK: - Private

    private let shortcutsRepo = Repository<[TextShortcut]>(key: "textShortcuts.shortcuts")
    private let enabledRepo = Repository<Bool>(key: "textShortcuts.enabled")
    private let settingsRepo = Repository<TextShortcutsSettings>(key: "textShortcuts.settings")

    private let monitor = KeystrokeMonitor()
    private var monitorUpdateTask: Task<Void, Never>?

    init() {
        let settings = settingsRepo.load() ?? TextShortcutsSettings()
        self.opacity = settings.opacity
        self.alwaysOnTop = settings.alwaysOnTop
        self.shortcuts = shortcutsRepo.load() ?? []
        self.isEnabled = enabledRepo.load() ?? false
        self.isAccessibilityGranted = KeystrokeMonitor.isAccessibilityGranted()
        updateMonitorNow()
    }

    // MARK: - Shortcut management

    func addShortcut() {
        shortcuts.append(TextShortcut())
    }

    func removeShortcut(_ shortcut: TextShortcut) {
        shortcuts.removeAll { $0.id == shortcut.id }
    }

    // MARK: - Accessibility

    func requestAccessibility() {
        KeystrokeMonitor.requestAccessibility()
        pollAccessibility()
    }

    func checkAccessibility() {
        isAccessibilityGranted = KeystrokeMonitor.isAccessibilityGranted()
        if isAccessibilityGranted { updateMonitorNow() }
    }

    func pollAccessibility() {
        Task { @MainActor in
            for _ in 0..<30 {
                try? await Task.sleep(for: .seconds(2))
                checkAccessibility()
                if isAccessibilityGranted { break }
            }
        }
    }

    // MARK: - Monitor management

    /// Debounced update — avoids thrashing the event tap while editing shortcuts.
    private func scheduleMonitorUpdate() {
        monitorUpdateTask?.cancel()
        monitorUpdateTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            updateMonitorNow()
        }
    }

    private func updateMonitorNow() {
        if isEnabled && isAccessibilityGranted {
            monitor.start(shortcuts: shortcuts)
        } else {
            monitor.stop()
        }
    }

    // MARK: - Persistence

    private func persistShortcuts() { shortcutsRepo.save(shortcuts) }
    private func persistEnabled() { enabledRepo.save(isEnabled) }
    private func persistSettings() {
        settingsRepo.save(TextShortcutsSettings(opacity: opacity, alwaysOnTop: alwaysOnTop))
    }
}
