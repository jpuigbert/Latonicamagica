import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct MusicSettingsView: View {
    @ObservedObject var music: MusicService
    @ObservedObject var wallpaper: WallpaperService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Theme.fons.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Capçalera
                VStack(spacing: 6) {
                    Text("🎨 Música, sons i fons")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundColor(Theme.lilaFort)
                    
                    Text("El joc ja porta música i sons integrats 🎶.\nPots triar fitxers propis i una imatge de fons.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Llista de moments
                ScrollView {
                    VStack(spacing: 10) {
                        wallpaperRow
                        
                        ForEach(SoundSlot.allCases) { slot in
                            SoundRow(
                                slot: slot,
                                url: music.soundURLs[slot],
                                onPick: { triarSo(slot: slot) },
                                onPreview: { music.preview(slot) },
                                onRemove: { music.removeSound(for: slot) }
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Peu
                HStack(spacing: 14) {
                    Button("Torna als sons per defecte") {
                        for slot in SoundSlot.allCases {
                            music.removeSound(for: slot)
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(Theme.rosaFort)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Fet!")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.white)
                    .background(Capsule().fill(Theme.lilaFort))
                    .shadow(color: Theme.lilaFort.opacity(0.4), radius: 6, y: 4)
                }
            }
            .padding(24)
        }
        .frame(width: 580, height: 560)
    }
    
    // MARK: - Fila del wallpaper
    
    private var wallpaperRow: some View {
        HStack(spacing: 12) {
            Text("🖼️")
                .font(.system(size: 26))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Imatge de fons (wallpaper)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.lilaFort)
                Text(wallpaper.fileURL?.lastPathComponent
                     ?? "Fons actual: degradat pastel del joc")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(wallpaper.fileURL == nil ? .secondary : .primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
            
            if wallpaper.fileURL != nil {
                Button(action: { wallpaper.removeWallpaper() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                }
                .buttonStyle(.plain)
                .foregroundColor(Theme.rosaFort)
                .help("Tornar al degradat pastel")
            }
            
            Button(action: { triaImatgeFons() }) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 18))
                    .padding(6)
            }
            .buttonStyle(.borderless)
            .foregroundColor(Theme.lilaFort)
            .help("Triar imatge JPG/PNG")
        }
        .padding(12)
        .background(Color.white.opacity(0.75))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.lilaFort.opacity(0.35), lineWidth: 1.5)
        )
    }
    
    // MARK: - Panells de selecció (NSOpenPanel natiu)
    //     El `.fileImporter` de SwiftUI es penjava dins d'un `.sheet`;
    //     l'NSOpenPanel d'AppKit funciona sense problema.
    
    private func triarSo(slot: SoundSlot) {
        let panel = NSOpenPanel()
        panel.title = "So per a «\(slot.displayName)»"
        panel.message = "Tria un fitxer d'àudio (mp3, wav, m4a…)"
        panel.allowedContentTypes = [.audio]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            music.setSound(for: slot, from: url)
        }
    }
    
    private func triaImatgeFons() {
        let panel = NSOpenPanel()
        panel.title = "Imatge de fons"
        panel.message = "Tria una imatge JPG o PNG del teu ordinador"
        panel.allowedContentTypes = [.png, .jpeg]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            wallpaper.setWallpaper(from: url)
        }
    }
}

private struct SoundRow: View {
    let slot: SoundSlot
    let url: URL?
    let onPick: () -> Void
    let onPreview: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Text(slot.emoji)
                .font(.system(size: 26))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(slot.displayName)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.lilaFort)
                Text(url?.lastPathComponent ?? "🎵 Son per defecte del joc")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(url == nil ? .secondary : .primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
            
            Button(action: onPreview) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 20))
            }
            .buttonStyle(.plain)
            .foregroundColor(Theme.lilaFort)
            .help("Escoltar")
            
            if url != nil {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                }
                .buttonStyle(.plain)
                .foregroundColor(Theme.rosaFort)
                .help("Tornar al so per defecte")
            }
            
            Button(action: onPick) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 18))
                    .padding(6)
            }
            .buttonStyle(.borderless)
            .foregroundColor(Theme.lilaFort)
            .help("Triar fitxer")
        }
        .padding(12)
        .background(Color.white.opacity(0.75))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.lilaFort.opacity(0.2), lineWidth: 1.5)
        )
    }
}
