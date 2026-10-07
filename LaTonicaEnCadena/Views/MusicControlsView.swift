import SwiftUI

struct MusicControlsView: View {
    @ObservedObject var music: MusicService
    
    var body: some View {
        HStack(spacing: 12) {
            MusicButton(
                emoji: music.musicEnabled ? "🎵" : "🔇",
                label: music.musicEnabled ? "Música ON" : "Música OFF",
                color: music.musicEnabled ? Theme.lilaFort : .gray
            ) {
                music.toggleMusic()
            }
            
            MusicButton(
                emoji: music.sfxEnabled ? "🔔" : "🔕",
                label: music.sfxEnabled ? "Sons ON" : "Sons OFF",
                color: music.sfxEnabled ? Theme.rosaFort : .gray
            ) {
                music.toggleSFX()
            }
        }
    }
}

private struct MusicButton: View {
    let emoji: String
    let label: String
    let color: Color
    let accio: () -> Void
    
    var body: some View {
        Button(action: accio) {
            HStack(spacing: 6) {
                Text(emoji).font(.system(size: 18))
                Text(label)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.75))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.5), lineWidth: 2)
            )
            .cornerRadius(16)
            .foregroundColor(color)
        }
        .buttonStyle(.plain)
    }
}
