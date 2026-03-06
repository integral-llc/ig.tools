import Foundation
import SwiftUI

enum TranscriptionPhase: Equatable, Sendable {
    case idle
    case checkingDependencies
    case downloading(progress: Double)
    case extractingAudio
    case transcribing(progress: Double)
    case finished(outputPath: String)
    case failed(message: String)

    var isRunning: Bool {
        switch self {
        case .checkingDependencies, .downloading, .extractingAudio, .transcribing:
            return true
        default:
            return false
        }
    }

    var progressValue: Double {
        switch self {
        case .checkingDependencies: return 0.02
        case .downloading(let p): return 0.05 + p * 0.40
        case .extractingAudio: return 0.46
        case .transcribing(let p): return 0.47 + p * 0.53
        case .finished: return 1.0
        default: return 0.0
        }
    }

    var statusLabel: String {
        switch self {
        case .idle: return ""
        case .checkingDependencies: return "Checking dependencies…"
        case .downloading(let p): return "Downloading video (\(Int(p * 100))%)…"
        case .extractingAudio: return "Extracting audio…"
        case .transcribing(let p): return "Transcribing (\(Int(p * 100))%)…"
        case .finished(let path): return "Done — \(path)"
        case .failed(let msg): return msg
        }
    }
}

@Observable
@MainActor
final class YouTubeTranscriberState {
    var youtubeURL: String = ""
    var outputFolder: String = "" { didSet { persistSettings() } }
    var phase: TranscriptionPhase = .idle
    var missingDependency: DependencyChecker.CheckResult? = nil
    var videoTitle: String? = nil
    var logLines: [String] = []

    var opacity: Double { didSet { persistSettings() } }
    var alwaysOnTop: Bool { didSet { persistSettings() } }
    var whisperModel: String { didSet { persistSettings() } }

    private let settingsRepo = Repository<YouTubeTranscriberSettings>(key: "ytTranscriber.settings")
    private var activeProcess: Process?
    // Mutable scratch storage used during a single run (MainActor-isolated, not captured by @Sendable closures)
    private var capturedAudioFile: String? = nil
    private var capturedTranscribeProgress: Double = 0.0

    init() {
        let s = settingsRepo.load() ?? YouTubeTranscriberSettings()
        self.opacity = s.opacity
        self.alwaysOnTop = s.alwaysOnTop
        self.whisperModel = s.whisperModel
        self.outputFolder = s.lastOutputFolder
    }

    // MARK: - Public API

    func start() {
        guard !phase.isRunning else { return }
        logLines = []
        capturedAudioFile = nil
        capturedTranscribeProgress = 0.0
        videoTitle = nil
        phase = .checkingDependencies
        Task { await run() }
    }

    func cancel() {
        activeProcess?.terminate()
        activeProcess = nil
        phase = .idle
        appendLog("Cancelled.")
    }

    func revealInFinder(_ path: String) {
        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
    }

    func openInstructions(for dep: DependencyChecker.CheckResult) {
        let alert = NSAlert()
        alert.messageText = "\(dep.dependency.displayName) not found"
        alert.informativeText = dep.dependency.installInstructions
        alert.addButton(withTitle: "Copy Command")
        alert.addButton(withTitle: "Dismiss")
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(dep.dependency.installCommand, forType: .string)
        }
    }

    // MARK: - Private

    private func run() async {
        // 1. Dependency check
        if let missing = DependencyChecker.firstMissing() {
            missingDependency = missing
            phase = .failed(message: "\(missing.dependency.displayName) is not installed.")
            return
        }
        missingDependency = nil

        // 2. Validate inputs
        let urlString = youtubeURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !urlString.isEmpty else {
            phase = .failed(message: "Please enter a YouTube URL.")
            return
        }
        var folder = outputFolder.trimmingCharacters(in: .whitespacesAndNewlines)
        if folder.isEmpty { folder = NSHomeDirectory() + "/Downloads" }

        // 3. Fetch video title (fast metadata-only call)
        let ytDlpBin = DependencyChecker.checkAll().first { $0.dependency == .ytDlp }?.path ?? "/usr/local/bin/yt-dlp"
        var collectedTitle = ""
        _ = await runProcess(
            executable: ytDlpBin,
            arguments: ["--print", "title", "--no-playlist", "--no-warnings", urlString],
            onLine: { [weak self] line in
                guard let self else { return }
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                collectedTitle += (collectedTitle.isEmpty ? "" : " ") + trimmed
                self.videoTitle = collectedTitle
            }
        )

        // 4. Download video + extract audio via yt-dlp
        phase = .downloading(progress: 0)
        let outputTemplate = (folder as NSString).appendingPathComponent("%(title)s.%(ext)s")

        appendLog("Starting download: \(urlString)")

        var dlArgs = [
            urlString,
            "--extract-audio",
            "--audio-format", "mp3",
            "--audio-quality", "0",
            "--output", outputTemplate,
            "--newline",
            "--no-playlist",
        ]
        // Pass ffmpeg location explicitly — app bundles have a restricted PATH
        if let (_, ffmpegPath) = Optional(DependencyChecker.isAvailable("ffmpeg")), let path = ffmpegPath {
            dlArgs += ["--ffmpeg-location", (path as NSString).deletingLastPathComponent]
        }

        let dlResult = await runProcess(
            executable: ytDlpBin,
            arguments: dlArgs,
            onLine: { [weak self] line in
                guard let self else { return }
                self.appendLog(line)
                if line.contains("[download]"), let pct = Self.parseYtDlpProgress(line) {
                    self.phase = .downloading(progress: pct)
                }
                if line.contains("Destination:") {
                    let parts = line.components(separatedBy: "Destination:")
                    if let path = parts.last?.trimmingCharacters(in: .whitespaces) {
                        self.capturedAudioFile = path
                    }
                }
            }
        )

        guard dlResult == 0 else {
            phase = .failed(message: "Download failed (exit \(dlResult)). Check the URL and try again.")
            return
        }

        phase = .extractingAudio

        if capturedAudioFile == nil {
            capturedAudioFile = findLatestAudioFile(in: folder)
        }

        guard let audioFile = capturedAudioFile else {
            phase = .failed(message: "Could not locate downloaded audio file in \(folder).")
            return
        }

        appendLog("Audio file: \(audioFile)")

        // 4. Transcribe with mlx_whisper
        phase = .transcribing(progress: 0)
        capturedTranscribeProgress = 0.0
        let whisperBin = DependencyChecker.checkAll().first { $0.dependency == .mlxWhisper }?.path ?? "/usr/local/bin/mlx_whisper"
        let audioURL = URL(fileURLWithPath: audioFile)
        let textFile = audioURL.deletingPathExtension().appendingPathExtension("txt").path

        let whisperArgs = [
            audioFile,
            "--model", whisperModel,
            "--output-format", "txt",
            "--output-dir", folder,
        ]

        appendLog("Transcribing with model: \(whisperModel)")
        let wsResult = await runProcess(
            executable: whisperBin,
            arguments: whisperArgs,
            onLine: { [weak self] line in
                guard let self else { return }
                self.appendLog(line)
                if let p = Self.parseWhisperProgress(line) {
                    self.capturedTranscribeProgress = p
                    self.phase = .transcribing(progress: p)
                }
            }
        )

        guard wsResult == 0 else {
            phase = .failed(message: "Transcription failed (exit \(wsResult)).")
            return
        }

        appendLog("Transcription complete: \(textFile)")
        try? FileManager.default.removeItem(atPath: audioFile)
        appendLog("Cleaned up: \(audioFile)")
        outputFolder = folder
        phase = .finished(outputPath: textFile)
    }

    // MARK: - Process helpers

    /// Runs a process and streams stdout+stderr line-by-line to `onLine` on the main actor.
    private func runProcess(
        executable: String,
        arguments: [String],
        onLine: @escaping @MainActor @Sendable (String) -> Void
    ) async -> Int32 {
        await withCheckedContinuation { continuation in
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: executable)
            proc.arguments = arguments

            // App bundles inherit a stripped PATH; inject all common locations so
            // yt-dlp can find ffmpeg, Python tools can find their runtime, etc.
            let home = NSHomeDirectory()
            let enrichedPath = [
                "/opt/homebrew/bin",
                "/opt/homebrew/sbin",
                "/usr/local/bin",
                "/usr/bin",
                "/bin",
                "/usr/sbin",
                "/sbin",
                "\(home)/.local/bin",
                "\(home)/Library/Python/3.9/bin",
                "\(home)/Library/Python/3.10/bin",
                "\(home)/Library/Python/3.11/bin",
                "\(home)/Library/Python/3.12/bin",
                "\(home)/.pyenv/shims",
            ].joined(separator: ":")
            var env = ProcessInfo.processInfo.environment
            env["PATH"] = enrichedPath + ":" + (env["PATH"] ?? "")
            proc.environment = env

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            proc.standardOutput = stdoutPipe
            proc.standardError = stderrPipe

            stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
                for l in text.components(separatedBy: "\n") where !l.isEmpty {
                    Task { @MainActor in onLine(l) }
                }
            }
            stderrPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
                for l in text.components(separatedBy: "\n") where !l.isEmpty {
                    Task { @MainActor in onLine(l) }
                }
            }

            proc.terminationHandler = { p in
                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                stderrPipe.fileHandleForReading.readabilityHandler = nil
                continuation.resume(returning: p.terminationStatus)
            }

            do {
                try proc.run()
                Task { @MainActor [weak self] in self?.activeProcess = proc }
            } catch {
                let msg = "Failed to launch \(executable): \(error.localizedDescription)"
                continuation.resume(returning: -1)
                Task { @MainActor in onLine(msg) }
            }
        }
    }

    // MARK: - Parsing helpers (nonisolated — pure functions)

    nonisolated private static func parseYtDlpProgress(_ line: String) -> Double? {
        let pattern = #"\[download\]\s+([\d.]+)%"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
              let range = Range(match.range(at: 1), in: line),
              let value = Double(line[range])
        else { return nil }
        return min(value / 100.0, 1.0)
    }

    nonisolated private static func parseWhisperProgress(_ line: String) -> Double? {
        // mlx_whisper prints: "[00:01.000 --> 00:05.000]  text"
        let pattern = #"\[(\d+):(\d+)\."#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
              let mRange = Range(match.range(at: 1), in: line),
              let sRange = Range(match.range(at: 2), in: line),
              let minutes = Double(line[mRange]),
              let seconds = Double(line[sRange])
        else { return nil }
        let elapsed = minutes * 60 + seconds
        return min(elapsed / max(elapsed + 30, 1), 0.98)
    }

    private func findLatestAudioFile(in folder: String) -> String? {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(atPath: folder) else { return nil }
        let audioFiles = contents
            .filter { $0.hasSuffix(".m4a") || $0.hasSuffix(".mp3") || $0.hasSuffix(".wav") }
            .map { (folder as NSString).appendingPathComponent($0) }
            .compactMap { path -> (String, Date)? in
                guard let attrs = try? fm.attributesOfItem(atPath: path),
                      let mod = attrs[.modificationDate] as? Date else { return nil }
                return (path, mod)
            }
            .sorted { $0.1 > $1.1 }
        return audioFiles.first?.0
    }

    private func appendLog(_ line: String) {
        logLines.append(line)
        if logLines.count > 500 { logLines.removeFirst(logLines.count - 500) }
    }

    // MARK: - Persistence

    private func persistSettings() {
        settingsRepo.save(YouTubeTranscriberSettings(
            opacity: opacity,
            alwaysOnTop: alwaysOnTop,
            lastOutputFolder: outputFolder,
            whisperModel: whisperModel
        ))
    }
}
