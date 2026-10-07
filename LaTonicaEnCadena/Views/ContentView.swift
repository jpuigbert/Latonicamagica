import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        ZStack {
            FonsView(wallpaper: WallpaperService.shared)
            
            VStack(spacing: 22) {
                header
                MarcadorView(viewModel: viewModel)
                ParaulaView(viewModel: viewModel)
                ClassificacioView(viewModel: viewModel)
                FeedbackView(viewModel: viewModel)
                Spacer()
                ControlsView(viewModel: viewModel)
            }
            .padding(24)
        }
        .frame(minWidth: 780, minHeight: 820)
        .sheet(isPresented: $appState.showMusicSettings) {
            MusicSettingsView(music: viewModel.music,
                              wallpaper: WallpaperService.shared)
        }
        .background {
            // La tecla Intro valida l'opció seleccionada i, si la pregunta
            // ja està respondida, avança al torn següent.
            Button("Validar (Intro)") {
                if viewModel.isAnswered {
                    viewModel.advanceTurn()
                } else {
                    viewModel.checkAnswer()
                }
            }
            .keyboardShortcut(.defaultAction)
            .frame(width: 1, height: 1)
            .opacity(0)
        }
    }
    
    private var header: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Text("🦄").font(.system(size: 40))
                Text("La tònica màgica")
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.lilaFort)
                Text("🌈").font(.system(size: 40))
                
                // Botó visible per obrir el menú de música i sons
                Button {
                    appState.showMusicSettings = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14))
                        Text("Música i sons")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Theme.lilaFort))
                    .shadow(color: Theme.lilaFort.opacity(0.4), radius: 5, y: 3)
                }
                .buttonStyle(.plain)
                .help("Tria els sons del joc (⌘,)")
                .padding(.leading, 6)
            }
            
            Text("Endevina on sona més fort la paraula!")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(Theme.rosaFort)
            
            Toggle(isOn: $viewModel.useAPI) {
                Text("🌐 Buscar paraules noves a Internet")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .toggleStyle(.switch)
            .tint(Theme.lilaFort)
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.6))
            .cornerRadius(20)
            
            MusicControlsView(music: viewModel.music)
        }
    }
}
