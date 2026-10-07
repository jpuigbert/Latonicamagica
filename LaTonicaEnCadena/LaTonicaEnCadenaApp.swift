import SwiftUI

@main
struct LaTonicaEnCadenaApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 780, height: 820)
        .commands {
            // Menú visible a la barra de menús: "Joc > Configura els sons…"
            CommandMenu("Joc") {
                Button("Configura els sons…") {
                    appState.showMusicSettings = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
