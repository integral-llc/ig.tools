import SwiftUI

struct LayoutSwitcherSettingsView: View {
    @Bindable var state: LayoutSwitcherState

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

            Text("Detection")
                .font(.headline)

            Stepper("Min word length: \(state.minWordLength)", value: $state.minWordLength, in: 3...8)

            Divider()

            Text("Feedback")
                .font(.headline)

            Toggle("Play sound on switch", isOn: $state.playSoundOnSwitch)
        }
        .padding()
        .frame(width: 260)
    }
}
