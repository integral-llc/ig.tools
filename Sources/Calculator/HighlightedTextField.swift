import SwiftUI
import AppKit

/// Shared controller for autocomplete communication between the text field and the parent view.
@Observable
@MainActor
final class InputFieldController {
    var suggestions: [String] = []
    var selectedIndex: Int = -1
    @ObservationIgnored var performCompletion: ((String) -> Void)?

    func complete(with name: String) {
        performCompletion?(name)
        selectedIndex = -1
    }

    func moveUp() {
        guard !suggestions.isEmpty else { return }
        if selectedIndex <= 0 {
            selectedIndex = suggestions.count - 1
        } else {
            selectedIndex -= 1
        }
    }

    func moveDown() {
        guard !suggestions.isEmpty else { return }
        if selectedIndex >= suggestions.count - 1 {
            selectedIndex = 0
        } else {
            selectedIndex += 1
        }
    }

    var selectedSuggestion: String? {
        guard selectedIndex >= 0 && selectedIndex < suggestions.count else { return nil }
        return suggestions[selectedIndex]
    }
}

/// An NSTextField wrapper that highlights $variable tokens (green = defined, red = undefined)
/// and drives autocomplete suggestions via `InputFieldController`.
struct HighlightedTextField: NSViewRepresentable {
    @Binding var text: String
    let variables: Set<String>
    let controller: InputFieldController
    let onSubmit: () -> Void
    let onChange: () -> Void

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField()
        field.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        field.isBezeled = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.delegate = context.coordinator
        field.placeholderString = "Expression\u{2026}"
        field.lineBreakMode = .byClipping
        context.coordinator.textField = field
        DispatchQueue.main.async {
            field.window?.makeFirstResponder(field)
        }
        return field
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        context.coordinator.parent = self
        guard !context.coordinator.suppressUpdate else { return }
        if nsView.stringValue != text {
            nsView.stringValue = text
            if let editor = nsView.currentEditor() as? NSTextView {
                context.coordinator.applyHighlighting(to: editor)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    // MARK: - Coordinator

    @MainActor
    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: HighlightedTextField
        var suppressUpdate = false
        weak var textField: NSTextField?
        private weak var activeEditor: NSTextView?

        init(parent: HighlightedTextField) {
            self.parent = parent
            super.init()
            parent.controller.performCompletion = { [weak self] name in
                self?.completeWithVariable(name)
            }
        }

        // MARK: NSTextFieldDelegate

        nonisolated func controlTextDidBeginEditing(_ obj: Notification) {
            let editor = obj.userInfo?["NSFieldEditor"] as? NSTextView
            MainActor.assumeIsolated {
                activeEditor = editor
            }
        }

        nonisolated func controlTextDidChange(_ obj: Notification) {
            guard let editor = obj.userInfo?["NSFieldEditor"] as? NSTextView else { return }
            MainActor.assumeIsolated {
                activeEditor = editor
                suppressUpdate = true
                parent.text = editor.string
                parent.onChange()
                suppressUpdate = false
                applyHighlighting(to: editor)
                updateSuggestions(in: editor)
            }
        }

        nonisolated func controlTextDidEndEditing(_ obj: Notification) {
            MainActor.assumeIsolated {
                parent.controller.suggestions = []
                activeEditor = nil
            }
        }

        nonisolated func control(
            _ control: NSControl,
            textView: NSTextView,
            doCommandBy sel: Selector
        ) -> Bool {
            MainActor.assumeIsolated {
                let ctrl = parent.controller
                let hasSuggestions = !ctrl.suggestions.isEmpty

                switch sel {
                case #selector(NSResponder.insertNewline(_:)):
                    // If a suggestion is selected, complete it instead of submitting
                    if let selected = ctrl.selectedSuggestion {
                        completeWithVariable(selected, in: textView)
                        return true
                    }
                    parent.onSubmit()
                    ctrl.suggestions = []
                    ctrl.selectedIndex = -1
                    DispatchQueue.main.async { [weak self] in
                        if let editor = self?.activeEditor {
                            self?.applyHighlighting(to: editor)
                        }
                    }
                    return true
                case #selector(NSResponder.moveUp(_:)):
                    if hasSuggestions {
                        ctrl.moveUp()
                        return true
                    }
                    return false
                case #selector(NSResponder.moveDown(_:)):
                    if hasSuggestions {
                        ctrl.moveDown()
                        return true
                    }
                    return false
                case #selector(NSResponder.insertTab(_:)):
                    let target = ctrl.selectedSuggestion ?? ctrl.suggestions.first
                    if let name = target {
                        completeWithVariable(name, in: textView)
                        return true
                    }
                    return false
                case #selector(NSResponder.cancelOperation(_:)):
                    if hasSuggestions {
                        ctrl.suggestions = []
                        ctrl.selectedIndex = -1
                        return true
                    }
                    return false
                default:
                    return false
                }
            }
        }

        // MARK: - Highlighting

        func applyHighlighting(to textView: NSTextView) {
            guard let storage = textView.textStorage else { return }
            let text = storage.string as NSString
            let fullRange = NSRange(location: 0, length: text.length)
            guard fullRange.length > 0 else { return }

            let savedSelection = textView.selectedRange()

            storage.beginEditing()
            let font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
            storage.addAttribute(.font, value: font, range: fullRange)
            storage.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange)

            guard let regex = try? NSRegularExpression(pattern: "\\$([a-zA-Z_][a-zA-Z0-9_]*)?") else {
                storage.endEditing()
                return
            }

            for match in regex.matches(in: text as String, range: fullRange) {
                let nameRange = match.range(at: 1)
                let color: NSColor
                if nameRange.location != NSNotFound {
                    let name = text.substring(with: nameRange)
                    color = parent.variables.contains(name) ? .systemGreen : .systemRed
                } else {
                    color = .systemOrange
                }
                storage.addAttribute(.foregroundColor, value: color, range: match.range)
            }

            storage.endEditing()
            textView.setSelectedRange(savedSelection)
        }

        // MARK: - Autocomplete

        func updateSuggestions(in textView: NSTextView) {
            let text = textView.string
            let cursor = textView.selectedRange().location

            guard let (prefix, _) = variableTokenAtCursor(in: text, cursor: cursor) else {
                parent.controller.suggestions = []
                return
            }

            let allVars = parent.variables.sorted()
            let filtered: [String]
            if prefix.isEmpty {
                filtered = allVars
            } else {
                filtered = allVars.filter {
                    $0.lowercased().hasPrefix(prefix.lowercased()) && $0.lowercased() != prefix.lowercased()
                }
            }
            parent.controller.suggestions = filtered
            parent.controller.selectedIndex = -1
        }

        func completeWithVariable(_ name: String, in textView: NSTextView? = nil) {
            let tv: NSTextView
            if let provided = textView {
                tv = provided
            } else if let editor = activeEditor {
                tv = editor
            } else if let field = textField, let ed = field.currentEditor() as? NSTextView {
                tv = ed
            } else {
                // Fallback: modify text directly
                fallbackComplete(name)
                return
            }

            let text = tv.string
            let cursor = tv.selectedRange().location
            guard let (_, range) = variableTokenAtCursor(in: text, cursor: cursor) else {
                fallbackComplete(name)
                return
            }

            let replacement = "$\(name)"
            tv.replaceCharacters(in: range, with: replacement)
            let newCursor = range.location + (replacement as NSString).length
            tv.setSelectedRange(NSRange(location: newCursor, length: 0))

            suppressUpdate = true
            parent.text = tv.string
            parent.onChange()
            parent.controller.suggestions = []
            suppressUpdate = false

            applyHighlighting(to: tv)
        }

        private func fallbackComplete(_ name: String) {
            let pattern = "\\$([a-zA-Z_][a-zA-Z0-9_]*)?$"
            if let range = parent.text.range(of: pattern, options: .regularExpression) {
                parent.text.replaceSubrange(range, with: "$\(name)")
                parent.onChange()
            }
            parent.controller.suggestions = []
        }

        private func variableTokenAtCursor(in text: String, cursor: Int) -> (prefix: String, range: NSRange)? {
            let nsText = text as NSString
            guard cursor > 0 else { return nil }

            var pos = cursor - 1
            while pos >= 0 {
                let charCode = nsText.character(at: pos)
                guard let scalar = Unicode.Scalar(charCode) else { break }
                let ch = Character(scalar)
                if ch.isLetter || ch.isNumber || ch == "_" {
                    pos -= 1
                } else if ch == "$" {
                    let prefix = nsText.substring(with: NSRange(location: pos + 1, length: cursor - pos - 1))
                    let range = NSRange(location: pos, length: cursor - pos)
                    return (prefix, range)
                } else {
                    break
                }
            }
            return nil
        }
    }
}
