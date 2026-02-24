import SwiftUI

/// Dialog shown on launch when accessibility permissions are not yet granted.
/// Watches for status changes and shows a green checkmark once granted.
struct AccessibilityPromptView: View {
    @Bindable var state: TextShortcutsState
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            if state.isAccessibilityGranted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)
                    .transition(.scale.combined(with: .opacity))

                Text("Accessibility Access Granted")
                    .font(.headline)

                Text("Text Shortcuts is ready to use.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "lock.shield")
                    .font(.system(size: 48))
                    .foregroundStyle(.orange)

                Text("Accessibility Access Required")
                    .font(.headline)

                Text("IG Tools needs Accessibility access to monitor keystrokes for the Text Shortcuts feature.\n\nPlease grant access in System Settings.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button("Open System Settings") {
                    KeystrokeMonitor.requestAccessibility()
                    state.pollAccessibility()
                }
                .buttonStyle(.borderedProminent)
            }

            Button("Dismiss") {
                onDismiss()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
        .animation(.easeInOut(duration: 0.3), value: state.isAccessibilityGranted)
        .padding(24)
        .frame(width: 340)
        .onChange(of: state.isAccessibilityGranted) { _, granted in
            if granted {
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(2))
                    onDismiss()
                }
            }
        }
    }
}
