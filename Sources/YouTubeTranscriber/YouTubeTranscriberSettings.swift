import Foundation

struct YouTubeTranscriberSettings: ToolSettings {
    var opacity: Double = 1.0
    var alwaysOnTop: Bool = true
    var lastOutputFolder: String = ""
    var whisperModel: String = "mlx-community/whisper-large-v3-turbo"
}
