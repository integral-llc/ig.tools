import SwiftUI

struct YouTubeTranscriberSettingsView: View {
    @Bindable var state: YouTubeTranscriberState

    private let modelOptions = [
        "mlx-community/whisper-tiny",
        "mlx-community/whisper-base",
        "mlx-community/whisper-small",
        "mlx-community/whisper-medium",
        "mlx-community/whisper-large-v3",
        "mlx-community/whisper-large-v3-turbo",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Window")
                .font(.headline)

            HStack {
                Text("Opacity")
                Slider(value: $state.opacity, in: 0.3...1.0, step: 0.05)
                Text("\(Int(state.opacity * 100))%")
                    .monospacedDigit()
                    .frame(width: 36, alignment: .trailing)
            }

            Toggle("Always on top", isOn: $state.alwaysOnTop)

            Divider()

            Text("Transcription")
                .font(.headline)

            HStack {
                Text("Whisper model")
                Spacer()
                Picker("", selection: $state.whisperModel) {
                    ForEach(modelOptions, id: \.self) { model in
                        Text(model.components(separatedBy: "/").last ?? model).tag(model)
                    }
                }
                .labelsHidden()
                .frame(width: 200)
            }

            Text("Larger models are more accurate but slower. Turbo is recommended for most use cases.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 320)
    }
}
