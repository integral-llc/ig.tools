import SwiftUI
import AppKit

struct YouTubeTranscriberView: View {
    @Bindable var state: YouTubeTranscriberState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            inputSection
            progressSection
            if let missing = state.missingDependency {
                dependencyAlert(for: missing)
            }
            logSection
        }
        .padding(20)
        .frame(minWidth: 560, minHeight: 380)
    }

    // MARK: - Subviews

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            LabeledField(label: "YouTube URL") {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("https://www.youtube.com/watch?v=...", text: $state.youtubeURL)
                        .textFieldStyle(.roundedBorder)
                        .disabled(state.phase.isRunning)
                    if let title = state.videoTitle {
                        Text(title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .padding(.leading, 4)
                    }
                }
            }

            LabeledField(label: "Output Folder") {
                HStack(spacing: 6) {
                    TextField("~/Downloads", text: $state.outputFolder)
                        .textFieldStyle(.roundedBorder)
                        .disabled(state.phase.isRunning)
                    Button("Choose…") { chooseFolder() }
                        .disabled(state.phase.isRunning)
                }
            }

            HStack {
                Spacer()
                if state.phase.isRunning {
                    Button("Cancel") { state.cancel() }
                        .buttonStyle(.bordered)
                } else {
                    Button("Start") { state.start() }
                        .buttonStyle(.borderedProminent)
                        .disabled(state.youtubeURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .keyboardShortcut(.return, modifiers: .command)
                }
            }
        }
    }

    @ViewBuilder
    private var progressSection: some View {
        let phase = state.phase
        if phase != .idle {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    statusIcon(for: phase)
                    Text(phase.statusLabel)
                        .font(.callout)
                        .foregroundStyle(statusColor(for: phase))
                        .lineLimit(2)
                    Spacer()
                    if case .finished(let path) = phase {
                        Button("Reveal") { state.revealInFinder(path) }
                            .buttonStyle(.link)
                            .font(.callout)
                    }
                }

                if phase.isRunning {
                    ProgressView(value: phase.progressValue)
                        .progressViewStyle(.linear)
                } else if case .finished = phase {
                    ProgressView(value: 1.0)
                        .progressViewStyle(.linear)
                        .tint(.green)
                } else if case .failed = phase {
                    ProgressView(value: 0)
                        .progressViewStyle(.linear)
                        .tint(.red)
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .controlBackgroundColor)))
        }
    }

    private func dependencyAlert(for missing: DependencyChecker.CheckResult) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(missing.dependency.displayName) is required but not installed.")
                    .font(.callout).bold()
                Text(installHint(for: missing.dependency))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("How to Install") { state.openInstructions(for: missing) }
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.1))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.orange.opacity(0.3)))
        )
    }

    @ViewBuilder
    private var logSection: some View {
        if !state.logLines.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("Log")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 1) {
                            ForEach(Array(state.logLines.enumerated()), id: \.offset) { idx, line in
                                Text(line)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .id(idx)
                            }
                        }
                        .padding(8)
                    }
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color(nsColor: .textBackgroundColor)))
                    .frame(height: 120)
                    .onChange(of: state.logLines.count) { _, _ in
                        proxy.scrollTo(state.logLines.count - 1, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Select Folder"
        if panel.runModal() == .OK, let url = panel.url {
            state.outputFolder = url.path
        }
    }

    @ViewBuilder
    private func statusIcon(for phase: TranscriptionPhase) -> some View {
        switch phase {
        case .finished:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        case .failed:
            Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
        default:
            ProgressView().controlSize(.small)
        }
    }

    private func statusColor(for phase: TranscriptionPhase) -> Color {
        switch phase {
        case .failed: return .red
        case .finished: return .green
        default: return .primary
        }
    }

    private func installHint(for dep: DependencyChecker.Dependency) -> String {
        switch dep {
        case .brew: return "Visit brew.sh or run the install command in Terminal."
        case .ytDlp: return "Run: brew install yt-dlp"
        case .mlxWhisper: return "Run: pip install mlx-whisper"
        }
    }
}

// MARK: - Helper view

private struct LabeledField<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(label)
                .frame(width: 110, alignment: .trailing)
                .foregroundStyle(.secondary)
                .font(.callout)
            content()
        }
    }
}
