import Foundation

/// A single text expansion shortcut: trigger text → replacement text.
struct TextShortcut: Identifiable, Codable, Sendable {
    let id: UUID
    var trigger: String
    var replacement: String
    var isEnabled: Bool

    init(id: UUID = UUID(), trigger: String = "", replacement: String = "", isEnabled: Bool = true) {
        self.id = id
        self.trigger = trigger
        self.replacement = replacement
        self.isEnabled = isEnabled
    }
}
