import KeyboardShortcuts
import Observation

extension KeyboardShortcuts.Name {
    static let toggleCalculator = Self("toggleCalculator")
}

/// Manages global keyboard shortcut registration.
@Observable
@MainActor
final class HotkeyManager {
    func setup() {
        // Shortcuts are handled declaratively via KeyboardShortcuts;
        // additional imperative setup can be added here.
    }
}
