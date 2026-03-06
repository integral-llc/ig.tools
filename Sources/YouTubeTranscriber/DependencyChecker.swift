import Foundation

/// Checks for required CLI dependencies and provides install instructions.
struct DependencyChecker: Sendable {
    enum Dependency: String, CaseIterable, Sendable {
        case brew = "brew"
        case ytDlp = "yt-dlp"
        case mlxWhisper = "mlx_whisper"

        var displayName: String {
            switch self {
            case .brew: return "Homebrew"
            case .ytDlp: return "yt-dlp"
            case .mlxWhisper: return "mlx_whisper"
            }
        }

        var installCommand: String {
            switch self {
            case .brew:
                return #"/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)""#
            case .ytDlp:
                return "brew install yt-dlp"
            case .mlxWhisper:
                return "pip install mlx-whisper"
            }
        }

        var installInstructions: String {
            switch self {
            case .brew:
                return "Install Homebrew by running the following command in Terminal:\n\n\(installCommand)"
            case .ytDlp:
                return "Install yt-dlp via Homebrew:\n\n\(installCommand)"
            case .mlxWhisper:
                return "Install mlx_whisper via pip:\n\n\(installCommand)\n\nNote: requires Python 3.9+ and an Apple Silicon Mac."
            }
        }
    }

    struct CheckResult: Sendable {
        let dependency: Dependency
        let isAvailable: Bool
        let path: String?
    }

    /// Searches well-known PATH locations for an executable.
    static func isAvailable(_ name: String) -> (Bool, String?) {
        let home = NSHomeDirectory()
        var searchPaths = [
            "/usr/local/bin",
            "/opt/homebrew/bin",
            "/usr/bin",
            "/bin",
            "/usr/sbin",
            "/sbin",
            "/opt/homebrew/sbin",
            "\(home)/.local/bin",
        ]
        // ~/Library/Python/<version>/bin — pip --user installs
        let pythonUserBase = "\(home)/Library/Python"
        if let versions = try? FileManager.default.contentsOfDirectory(atPath: pythonUserBase) {
            for v in versions.sorted(by: >) {
                searchPaths.append("\(pythonUserBase)/\(v)/bin")
            }
        }
        // ~/.pyenv/versions/*/bin
        let pyenvBase = "\(home)/.pyenv/versions"
        if let versions = try? FileManager.default.contentsOfDirectory(atPath: pyenvBase) {
            for v in versions.sorted(by: >) {
                searchPaths.append("\(pyenvBase)/\(v)/bin")
            }
        }
        for dir in searchPaths {
            let fullPath = "\(dir)/\(name)"
            if FileManager.default.isExecutableFile(atPath: fullPath) {
                return (true, fullPath)
            }
        }
        // Fall back to `which` (respects the user's login shell PATH)
        if let path = runWhich(name) {
            return (true, path)
        }
        return (false, nil)
    }

    private static func runWhich(_ name: String) -> String? {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        proc.arguments = [name]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = Pipe()
        do {
            try proc.run()
            proc.waitUntilExit()
            guard proc.terminationStatus == 0 else { return nil }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            return output?.isEmpty == false ? output : nil
        } catch {
            return nil
        }
    }

    /// Checks all required dependencies in order (brew → yt-dlp → mlx_whisper).
    static func checkAll() -> [CheckResult] {
        Dependency.allCases.map { dep in
            let (available, path) = isAvailable(dep.rawValue)
            return CheckResult(dependency: dep, isAvailable: available, path: path)
        }
    }

    /// Returns the first missing dependency, if any.
    static func firstMissing() -> CheckResult? {
        checkAll().first { !$0.isAvailable }
    }
}
