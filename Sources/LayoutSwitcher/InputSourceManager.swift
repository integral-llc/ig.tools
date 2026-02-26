import Carbon.HIToolbox
import Foundation

/// Wraps macOS TIS (Text Input Source) APIs for detecting and switching keyboard layouts.
enum InputSourceManager {

    /// Returns the identifier of the current keyboard input source (e.g. "com.apple.keylayout.US").
    static func currentInputSourceID() -> String? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return nil
        }
        guard let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else {
            return nil
        }
        return Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String
    }

    static func isRussianLayout() -> Bool {
        guard let id = currentInputSourceID() else { return false }
        return id.localizedCaseInsensitiveContains("Russian")
    }

    static func isEnglishLayout() -> Bool {
        !isRussianLayout()
    }

    // MARK: - Switching

    @discardableResult
    static func switchToRussian() -> Bool {
        switchToSource(matching: "Russian")
    }

    @discardableResult
    static func switchToEnglish() -> Bool {
        // Try common English layout identifiers
        switchToSource(matching: "ABC")
            || switchToSource(matching: "US")
            || switchToSource(matching: "British")
    }

    private static func switchToSource(matching keyword: String) -> Bool {
        guard let sources = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] else {
            return false
        }
        for source in sources {
            guard let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else {
                continue
            }
            let sourceID = Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String
            if sourceID.localizedCaseInsensitiveContains(keyword) {
                let status = TISSelectInputSource(source)
                return status == noErr
            }
        }
        return false
    }
}
