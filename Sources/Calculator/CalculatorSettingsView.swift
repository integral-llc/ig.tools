import SwiftUI

struct CalculatorSettingsView: View {
    @Bindable var state: CalculatorState

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
        }
        .padding()
        .frame(width: 260)
    }
}
