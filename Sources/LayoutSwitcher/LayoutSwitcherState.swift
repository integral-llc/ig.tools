import AppKit
import Carbon.HIToolbox
import CoreGraphics
import Foundation

// MARK: - Switch event model

struct SwitchEvent: Identifiable, Codable, Sendable {
    let id: UUID
    let date: Date
    let fromLayout: String
    let toLayout: String
    let original: String
    let replacement: String

    init(date: Date = Date(), fromLayout: String, toLayout: String, original: String, replacement: String) {
        self.id = UUID()
        self.date = date
        self.fromLayout = fromLayout
        self.toLayout = toLayout
        self.original = original
        self.replacement = replacement
    }
}

// MARK: - Thread-safe word buffer

/// Accumulates characters until a word boundary is reached, then returns the word.
final class LayoutBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var buffer: String = ""
    private var _isExpanding: Bool = false
    private var phraseHistory: [(word: String, boundary: Character)] = []

    var isExpanding: Bool {
        lock.lock(); defer { lock.unlock() }
        return _isExpanding
    }

    func setExpanding(_ value: Bool) {
        lock.lock(); defer { lock.unlock() }
        _isExpanding = value
    }

    func clear() {
        lock.lock(); defer { lock.unlock() }
        buffer = ""
        phraseHistory = []
    }

    /// Clears only the current word buffer, preserving phrase history.
    /// Used when the input source changes (which can be triggered spuriously
    /// by NSSpellChecker) — we don't want to lose accumulated phrase context.
    func clearCurrentWord() {
        lock.lock(); defer { lock.unlock() }
        buffer = ""
    }

    func appendToHistory(word: String, boundary: Character) {
        lock.lock(); defer { lock.unlock() }
        phraseHistory.append((word: word, boundary: boundary))
    }

    func drainHistory() -> [(word: String, boundary: Character)] {
        lock.lock(); defer { lock.unlock() }
        let items = phraseHistory
        phraseHistory = []
        return items
    }

    /// Returns the current buffer contents and clears it, or nil if empty/expanding.
    func forceComplete() -> String? {
        lock.lock(); defer { lock.unlock() }
        guard !_isExpanding, !buffer.isEmpty else { return nil }
        let word = buffer
        buffer = ""
        return word
    }

    /// Appends a character. If the character is a word boundary, returns the accumulated
    /// word and the boundary character. Otherwise returns nil.
    func append(_ char: Character) -> (word: String, boundary: Character)? {
        lock.lock(); defer { lock.unlock() }
        guard !_isExpanding else { return nil }

        let wordBoundaries: Set<Character> = [" ", "\n", "\t", ".", ",", "!", "?", ";", ":", "(", ")"]

        if wordBoundaries.contains(char) {
            let word = buffer
            buffer = ""
            return word.isEmpty ? nil : (word: word, boundary: char)
        }

        // Digits break word accumulation — not part of EN/RU words
        if char.isNumber {
            buffer = ""
            return nil
        }

        buffer.append(char)
        return nil
    }
}

// MARK: - Context for CGEvent callback

final class LayoutSwitcherContext: @unchecked Sendable {
    let buffer: LayoutBuffer
    var eventTap: CFMachPort?
    let onWordComplete: @Sendable (String, Character) -> Void

    init(buffer: LayoutBuffer, onWordComplete: @escaping @Sendable (String, Character) -> Void) {
        self.buffer = buffer
        self.onWordComplete = onWordComplete
    }
}

// MARK: - State

@Observable
@MainActor
final class LayoutSwitcherState {
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

    var playSoundOnSwitch: Bool {
        didSet { persistSettings() }
    }

    var minWordLength: Int {
        didSet { persistSettings() }
    }

    var recentSwitches: [SwitchEvent] = []

    // MARK: - Private

    private let enabledRepo = Repository<Bool>(key: "layoutSwitcher.enabled")
    private let settingsRepo = Repository<LayoutSwitcherSettings>(key: "layoutSwitcher.settings")
    private let switchesRepo = Repository<[SwitchEvent]>(key: "layoutSwitcher.recentSwitches")

    private let buffer = LayoutBuffer()
    private var context: LayoutSwitcherContext?
    private var runLoopSource: CFRunLoopSource?
    private var monitorUpdateTask: Task<Void, Never>?
    @ObservationIgnored private var inputSourceObserver: NSObjectProtocol?

    init() {
        let settings = settingsRepo.load() ?? LayoutSwitcherSettings()
        self.opacity = settings.opacity
        self.alwaysOnTop = settings.alwaysOnTop
        self.playSoundOnSwitch = settings.playSoundOnSwitch
        self.minWordLength = settings.minWordLength

        self.isEnabled = enabledRepo.load() ?? false
        self.recentSwitches = switchesRepo.load() ?? []
        self.isAccessibilityGranted = KeystrokeMonitor.isAccessibilityGranted()

        // Listen for layout changes — only clear current word buffer, not phrase history.
        // NSSpellChecker.checkSpelling(language:) can trigger spurious layout notifications
        // that would wipe accumulated phrase context needed for multi-word conversion.
        inputSourceObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.buffer.clearCurrentWord()
        }

        updateMonitorNow()
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

    private func scheduleMonitorUpdate() {
        monitorUpdateTask?.cancel()
        monitorUpdateTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            updateMonitorNow()
        }
    }

    private func updateMonitorNow() {
        print("LayoutSwitcher: updateMonitorNow — enabled=\(isEnabled) accessibility=\(isAccessibilityGranted)")
        if isEnabled && isAccessibilityGranted {
            startMonitor()
        } else {
            stopMonitor()
        }
    }

    // MARK: - Event tap

    private func startMonitor() {
        stopMonitor()
        buffer.clear()
        print("LayoutSwitcher: Starting monitor (enabled=\(isEnabled), accessibility=\(isAccessibilityGranted))")

        let ctx = LayoutSwitcherContext(buffer: buffer) { [weak self] word, boundary in
            Task { @MainActor in
                self?.handleWordComplete(word: word, boundary: boundary)
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
            callback: layoutSwitcherCallback,
            userInfo: ctxPtr
        ) else {
            Unmanaged<LayoutSwitcherContext>.fromOpaque(ctxPtr).release()
            print("LayoutSwitcher: Failed to create event tap. Check Accessibility permissions.")
            return
        }

        ctx.eventTap = tap
        self.context = ctx

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func stopMonitor() {
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

    // MARK: - Word detection

    private func handleWordComplete(word: String, boundary: Character) {
        print("LayoutSwitcher: Word complete: '\(word)' boundary='\(boundary)' len=\(word.count) min=\(minWordLength)")
        // Allow words shorter than minWordLength if LanguageHints can identify the mapped word
        if word.count < minWordLength {
            if word.count < 3 || !hasHintForMappedWord(word) {
                print("LayoutSwitcher: Skipping — word too short")
                return
            }
            print("LayoutSwitcher: Short word '\(word)' — proceeding (hint match on mapped word)")
        }

        let isRussian = InputSourceManager.isRussianLayout()
        let sourceID = InputSourceManager.currentInputSourceID() ?? "unknown"
        print("LayoutSwitcher: Current layout: \(isRussian ? "RU" : "EN") (\(sourceID))")

        if !shouldSwitch(word: word, isRussian: isRussian) {
            buffer.appendToHistory(word: word, boundary: boundary)
            return
        }

        // Drain phrase history and build full original/replacement strings
        let history = buffer.drainHistory()
        let mapFunc: (String) -> String? = isRussian
            ? { LayoutMap.mapRuToEn($0) }
            : { LayoutMap.mapEnToRu($0) }

        var fullOriginal = ""
        var fullReplacement = ""

        for item in history {
            fullOriginal += item.word + String(item.boundary)
            if let mapped = mapFunc(item.word) {
                fullReplacement += mapped + String(item.boundary)
            } else {
                fullReplacement += item.word + String(item.boundary)
            }
        }

        // Append the current triggering word (without boundary — performSwitch adds it)
        fullOriginal += word
        let currentMapped = mapFunc(word) ?? word
        fullReplacement += currentMapped

        print("LayoutSwitcher: Phrase switch: '\(fullOriginal)' → '\(fullReplacement)'")
        performSwitch(original: fullOriginal, replacement: fullReplacement, boundary: boundary, toRussian: !isRussian)
    }

    /// Returns true if the mapped version of the word is recognized by LanguageHints.
    /// Used to bypass minWordLength for short but confidently-identified words.
    private func hasHintForMappedWord(_ word: String) -> Bool {
        let isRussian = InputSourceManager.isRussianLayout()
        let mapped: String?
        if isRussian {
            mapped = LayoutMap.mapRuToEn(word)
        } else {
            mapped = LayoutMap.mapEnToRu(word)
        }
        guard let m = mapped else { return false }
        return isRussian
            ? LanguageHints.isLikelyEnglish(m)
            : LanguageHints.isLikelyRussian(m)
    }

    /// Determines whether the typed word should trigger a layout switch.
    /// Uses LanguageHints as authoritative for short/common words, overriding
    /// spell checker false positives on gibberish.
    private func shouldSwitch(word: String, isRussian: Bool) -> Bool {
        let currentLang = isRussian ? "ru" : "en"
        let otherLang = isRussian ? "en" : "ru"
        let hintCurrent = isRussian
            ? LanguageHints.isLikelyRussian(word)
            : LanguageHints.isLikelyEnglish(word)

        // If LanguageHints confirms the word belongs to current language, no switch
        if hintCurrent {
            print("LayoutSwitcher: '\(word)' confirmed by hints as \(currentLang) — no switch")
            return false
        }

        // Map the word to the other layout
        let candidate: String?
        if isRussian {
            candidate = LayoutMap.mapRuToEn(word)
        } else {
            candidate = LayoutMap.mapEnToRu(word)
        }

        guard let mapped = candidate else {
            print("LayoutSwitcher: Failed to map '\(word)' — no switch")
            return false
        }

        let hintOther = isRussian
            ? LanguageHints.isLikelyEnglish(mapped)
            : LanguageHints.isLikelyRussian(mapped)

        // If LanguageHints recognizes the mapped version, switch
        // (overrides spell checker false positives on the original)
        if hintOther {
            print("LayoutSwitcher: '\(word)' → '\(mapped)' confirmed by hints as \(otherLang) — switching")
            return true
        }

        // Fall back to spell checker
        let spellCurrent = isValidWord(word, language: currentLang)
        if spellCurrent {
            print("LayoutSwitcher: '\(word)' valid \(currentLang) by spell check — no switch")
            return false
        }

        let spellOther = isValidWord(mapped, language: otherLang)
        print("LayoutSwitcher: '\(word)' → '\(mapped)', spell check \(otherLang): \(spellOther)")
        return spellOther
    }

    private func isValidWord(_ word: String, language: String) -> Bool {
        // Lowercase before checking — NSSpellChecker treats ALL-CAPS as valid acronyms
        let lowered = word.lowercased()
        let checker = NSSpellChecker.shared
        let range = checker.checkSpelling(
            of: lowered,
            startingAt: 0,
            language: language,
            wrap: false,
            inSpellDocumentWithTag: 0,
            wordCount: nil
        )
        return range.location == NSNotFound
    }

    // MARK: - Switch + replace

    private func performSwitch(original: String, replacement: String, boundary: Character, toRussian: Bool) {
        buffer.setExpanding(true)

        if playSoundOnSwitch {
            NSSound(named: "Pop")?.play()
        }

        // Delete the original text (may include multiple words with boundaries) + final boundary character
        let deleteCount = original.count + 1
        for _ in 0..<deleteCount {
            postKey(keyCode: CGKeyCode(kVK_Delete), keyDown: true)
            postKey(keyCode: CGKeyCode(kVK_Delete), keyDown: false)
        }

        // Save clipboard, set replacement, paste
        let pasteboard = NSPasteboard.general
        let savedString = pasteboard.string(forType: .string)

        let pasteText = replacement + String(boundary)
        pasteboard.clearContents()
        pasteboard.setString(pasteText, forType: .string)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.postKey(keyCode: CGKeyCode(kVK_ANSI_V), keyDown: true, flags: .maskCommand)
            self?.postKey(keyCode: CGKeyCode(kVK_ANSI_V), keyDown: false, flags: .maskCommand)

            // Switch input source after paste (clipboard is Unicode, layout-independent)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                if toRussian {
                    InputSourceManager.switchToRussian()
                } else {
                    InputSourceManager.switchToEnglish()
                }

                // Restore clipboard
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let saved = savedString {
                        pasteboard.clearContents()
                        pasteboard.setString(saved, forType: .string)
                    }
                    self?.buffer.setExpanding(false)
                    self?.buffer.clear()

                    // Log the switch
                    Task { @MainActor in
                        self?.logSwitch(
                            fromLayout: toRussian ? "EN" : "RU",
                            toLayout: toRussian ? "RU" : "EN",
                            original: original,
                            replacement: replacement
                        )
                    }
                }
            }
        }
    }

    private func logSwitch(fromLayout: String, toLayout: String, original: String, replacement: String) {
        let event = SwitchEvent(
            fromLayout: fromLayout,
            toLayout: toLayout,
            original: original,
            replacement: replacement
        )
        recentSwitches.insert(event, at: 0)
        if recentSwitches.count > 50 { recentSwitches = Array(recentSwitches.prefix(50)) }
        switchesRepo.save(recentSwitches)
    }

    private func postKey(keyCode: CGKeyCode, keyDown: Bool, flags: CGEventFlags = []) {
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: keyDown) else { return }
        event.flags = flags
        event.post(tap: .cghidEventTap)
    }

    // MARK: - Persistence

    private func persistEnabled() { enabledRepo.save(isEnabled) }
    private func persistSettings() {
        settingsRepo.save(LayoutSwitcherSettings(
            opacity: opacity,
            alwaysOnTop: alwaysOnTop,
            playSoundOnSwitch: playSoundOnSwitch,
            minWordLength: minWordLength
        ))
    }
}

// MARK: - CGEvent C callback

private func layoutSwitcherCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else { return Unmanaged.passUnretained(event) }
    let ctx = Unmanaged<LayoutSwitcherContext>.fromOpaque(userInfo).takeUnretainedValue()

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

        // Return / Tab act as word boundaries (trigger detection before clearing)
        let wordBoundaryKeys: Set<Int64> = [
            Int64(kVK_Return), Int64(kVK_Tab), Int64(kVK_Space),
        ]

        if wordBoundaryKeys.contains(keyCode) {
            if let result = ctx.buffer.forceComplete() {
                let boundaryChar: Character = keyCode == Int64(kVK_Tab) ? "\t" : (keyCode == Int64(kVK_Return) ? "\n" : " ")
                print("LayoutSwitcher: [callback] Key boundary hit (keyCode=\(keyCode)), word='\(result)'")
                ctx.onWordComplete(result, boundaryChar)
            }
            break
        }

        // Clear buffer on navigation / non-character keys
        let clearKeys: Set<Int64> = [
            Int64(kVK_Escape), Int64(kVK_Delete), Int64(kVK_ForwardDelete),
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
            if let result = ctx.buffer.append(char) {
                print("LayoutSwitcher: [callback] Word boundary hit, word='\(result.word)'")
                ctx.onWordComplete(result.word, result.boundary)
                break
            }
        }

    default:
        break
    }

    return Unmanaged.passUnretained(event)
}
