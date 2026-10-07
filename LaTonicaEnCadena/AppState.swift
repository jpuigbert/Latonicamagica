import SwiftUI

/// Estat compartit a nivell d'aplicació (per obrir panells des de la
/// barra de menús, que viu a l'escena `App` i no pot accedir al
/// @StateObject del ContentView directament).
@MainActor
final class AppState: ObservableObject {
    @Published var showMusicSettings = false
}
