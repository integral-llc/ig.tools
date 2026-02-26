import SwiftUI

@main
struct IGToolsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            ForEach(appDelegate.registry.tools, id: \.id) { tool in
                Button {
                    ToolWindowManager.shared.toggleWindow(for: tool)
                } label: {
                    Label(tool.name, systemImage: tool.icon)
                }
            }

            Divider()

            Button("About IG Tools") {
                NSApp.orderFrontStandardAboutPanel(options: appDelegate.aboutPanelOptions)
                NSApp.activate(ignoringOtherApps: true)
            }

            Button("Quit") {
                ToolWindowManager.shared.closeAll()
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        } label: {
            Image(systemName: "function")
        }
        .menuBarExtraStyle(.menu)
    }
}