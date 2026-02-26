import Cocoa
import CoreGraphics
import Carbon.HIToolbox

// MARK: - Thread-safe keystroke buffer

/// Maintains a rolling character buffer and checks for trigger matches.
/// Thread-safe via NSLock for use from the CGEvent callback thread.
final class KeystrokeBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var buffer: String = ""
    private var maxLength: Int = 0
    private var _isExpanding: Bool = false
    private var triggers: [(trigger: String, replacement: String)] = []

    /// Configure the buffer with current triggers (sorted longest-first).
    func configure(triggers: [(trigger: String, replacement: String)], maxLength: Int) {
        lock.lock()
        defer { lock.unlock() }
        self.triggers = triggers
        self.maxLength = maxLength
        self.buffer = ""
        self._isExpanding = false
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }
        buffer = ""
    }

    var isExpanding: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isExpanding
    }

    func setExpanding(_ value: Bool) {
        lock.lock()
        defer { lock.unlock() }
        _isExpanding = value
    }

    /// Appends a character and returns the matched (trigger, replacement) or nil.
    func append(_ char: Character) -> (trigger: String, replacement: String)? {
        lock.lock()
        defer { lock.unlock() }

        guard !_isExpanding else { return nil }

        buffer.append(char)
        if buffer.count > maxLength {
            buffer.removeFirst(buffer.count - maxLength)
        }

        for entry in triggers {
            if buffer.hasSuffix(entry.trigger) {
                buffer = ""
                return entry
            }
        }
        return nil
    }
}

// MARK: - Context passed to CGEvent callback

/// Shared context accessible from the C callback. @unchecked Sendable because
/// the buffer is internally synchronized and the eventTap pointer is only
/// mutated from the main thread before/after the tap is active.
final class KeystrokeMonitorContext: @unchecked Sendable {
    let buffer: KeystrokeBuffer
    var eventTap: CFMachPort?
    let onMatch: @Sendable (String, String) -> Void

    init(buffer: KeystrokeBuffer, onMatch: @escaping @Sendable (String, String) -> Void) {
        self.buffer = buffer
        self.onMatch = onMatch
    }
}

// MARK: - Keystroke monitor

/// Global keystroke monitor that watches for trigger text and expands it.
@MainActor
final class KeystrokeMonitor {
    private var context: KeystrokeMonitorContext?
    private var runLoopSource: CFRunLoopSource?
    private let buffer = KeystrokeBuffer()
    var playSoundOnExpansion: Bool = true

    // MARK: - Accessibility

    nonisolated static func isAccessibilityGranted() -> Bool {
        AXIsProcessTrusted()
    }

    nonisolated static func requestAccessibility() {
        let options = ["AXTrustedCheckOptionPrompt" as CFString: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    // MARK: - Start / Stop

    func start(shortcuts: [TextShortcut]) {
        stop()

        let enabled = shortcuts.filter { $0.isEnabled && !$0.trigger.isEmpty }
        guard !enabled.isEmpty else { return }

        let sorted = enabled
            .map { (trigger: $0.trigger, replacement: $0.replacement) }
            .sorted { $0.trigger.count > $1.trigger.count }

        let maxLen = sorted.first?.trigger.count ?? 0
        buffer.configure(triggers: sorted, maxLength: maxLen)

        let ctx = KeystrokeMonitorContext(buffer: buffer) { [weak self] trigger, replacement in
            Task { @MainActor in
                self?.expand(trigger: trigger, replacement: replacement)
            }
        }

        let eventMask: CGEventMask =
            (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.leftMouseDown.rawValue)
            | (1 << CGEventType.rightMouseDown.rawValue)

        let ctxPtr = Unmanaged.passRetained(ctx).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: keystrokeCallback,
            userInfo: ctxPtr
        ) else {
            Unmanaged<KeystrokeMonitorContext>.fromOpaque(ctxPtr).release()
            print("TextShortcuts: Failed to create event tap. Check Accessibility permissions.")
            return
        }

        ctx.eventTap = tap
        self.context = ctx

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func stop() {
        if let ctx = context, let tap = ctx.eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        if let ctx = context {
            Unmanaged.passUnretained(ctx).release()
        }
        runLoopSource = nil
        context = nil
        buffer.clear()
    }

    // MARK: - Expansion

    private func expand(trigger: String, replacement: String) {
        buffer.setExpanding(true)

        if playSoundOnExpansion {
            NSSound(named: "Pop")?.play()
        }

        // 1. Simulate backspaces to delete the trigger
        for _ in 0..<trigger.count {
            postKey(keyCode: CGKeyCode(kVK_Delete), keyDown: true)
            postKey(keyCode: CGKeyCode(kVK_Delete), keyDown: false)
        }

        // 2. Save clipboard, set replacement, paste
        let pasteboard = NSPasteboard.general
        let savedString = pasteboard.string(forType: .string)

        pasteboard.clearContents()
        pasteboard.setString(replacement, forType: .string)

        // Small delay to let backspaces process before pasting
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.postKey(keyCode: CGKeyCode(kVK_ANSI_V), keyDown: true, flags: .maskCommand)
            self?.postKey(keyCode: CGKeyCode(kVK_ANSI_V), keyDown: false, flags: .maskCommand)

            // 3. Restore clipboard after paste completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                if let saved = savedString {
                    pasteboard.clearContents()
                    pasteboard.setString(saved, forType: .string)
                }
                self?.buffer.setExpanding(false)
            }
        }
    }

    private func postKey(keyCode: CGKeyCode, keyDown: Bool, flags: CGEventFlags = []) {
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: keyDown) else { return }
        event.flags = flags
        event.post(tap: .cghidEventTap)
    }
}

// MARK: - CGEvent C callback

private func keystrokeCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else { return Unmanaged.passUnretained(event) }
    let ctx = Unmanaged<KeystrokeMonitorContext>.fromOpaque(userInfo).takeUnretainedValue()

    switch type {
    case .tapDisabledByTimeout, .tapDisabledByUserInput:
        if let tap = ctx.eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }

    case .leftMouseDown, .rightMouseDown:
        ctx.buffer.clear()

    case .keyDown:
        guard !ctx.buffer.isExpanding else { break }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags

        // Ignore modifier combos (Cmd, Ctrl, Alt) — but allow Shift
        let modifierMask: CGEventFlags = [.maskCommand, .maskControl, .maskAlternate]
        if !flags.intersection(modifierMask).isEmpty {
            ctx.buffer.clear()
            break
        }

        // Clear buffer on navigation / non-character keys
        let clearKeys: Set<Int64> = [
            Int64(kVK_Escape), Int64(kVK_Delete), Int64(kVK_ForwardDelete),
            Int64(kVK_Return), Int64(kVK_Tab),
            Int64(kVK_LeftArrow), Int64(kVK_RightArrow),
            Int64(kVK_UpArrow), Int64(kVK_DownArrow),
            Int64(kVK_Home), Int64(kVK_End),
            Int64(kVK_PageUp), Int64(kVK_PageDown),
            Int64(kVK_F1), Int64(kVK_F2), Int64(kVK_F3), Int64(kVK_F4),
            Int64(kVK_F5), Int64(kVK_F6), Int64(kVK_F7), Int64(kVK_F8),
            Int64(kVK_F9), Int64(kVK_F10), Int64(kVK_F11), Int64(kVK_F12),
        ]

        if clearKeys.contains(keyCode) {
            ctx.buffer.clear()
            break
        }

        // Extract typed character
        var unicodeLength = 0
        var unicodeString = [UniChar](repeating: 0, count: 4)
        event.keyboardGetUnicodeString(
            maxStringLength: 4,
            actualStringLength: &unicodeLength,
            unicodeString: &unicodeString
        )

        guard unicodeLength > 0 else {
            ctx.buffer.clear()
            break
        }

        let str = String(utf16CodeUnits: Array(unicodeString.prefix(unicodeLength)), count: unicodeLength)
        for char in str {
            if let match = ctx.buffer.append(char) {
                ctx.onMatch(match.trigger, match.replacement)
                break
            }
        }

    default:
        break
    }

    return Unmanaged.passUnretained(event)
}
