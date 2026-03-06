import SwiftUI

struct YouTubeTranscriberTool: Tool {
    let id = "youtubeTranscriber"
    let name = "YT Transcriber"
    let icon = "captions.bubble"

    private let state: YouTubeTranscriberState

    init(state: YouTubeTranscriberState) {
        self.state = state
    }

    var opacity: Double { state.opacity }
    var alwaysOnTop: Bool { state.alwaysOnTop }
    var defaultSize: CGSize? { CGSize(width: 600, height: 460) }

    @MainActor
    func makeView() -> AnyView {
        AnyView(YouTubeTranscriberView(state: state))
    }

    @MainActor
    func makeSettingsView() -> AnyView {
        AnyView(YouTubeTranscriberSettingsView(state: state))
    }
}
