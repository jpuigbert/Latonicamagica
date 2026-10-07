import Foundation
import AVFoundation

/// Cada "moment" del joc que pot tenir un so assignat.
enum SoundSlot: String, CaseIterable, Identifiable {
    case background
    case correct
    case wrong
    case turn
    case reset
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .background: return "Música de fons"
        case .correct:    return "Encert"
        case .wrong:      return "Error"
        case .turn:       return "Canvi de torn"
        case .reset:      return "Reiniciar"
        }
    }
    
    var emoji: String {
        switch self {
        case .background: return "🎵"
        case .correct:    return "🌟"
        case .wrong:      return "💭"
        case .turn:       return "➡️"
        case .reset:      return "🔄"
        }
    }
    
    /// Si la pista es reprodueix en bucle.
    var isLoop: Bool { self == .background }
}

@MainActor
final class MusicService: ObservableObject {
    
    // MARK: - Estat publicat
    
    @Published var musicEnabled: Bool = true
    @Published var sfxEnabled: Bool = true
    @Published private(set) var soundURLs: [SoundSlot: URL] = [:]
    
    // MARK: - Propietats privades
    
    private var musicPlayer: AVAudioPlayer?
    private var sfxPlayers: [AVAudioPlayer] = []
    private var previewPlayer: AVAudioPlayer?
    private var scopedURLs: Set<URL> = []
    private let defaults = UserDefaults.standard
    
    // MARK: - Inicialització
    
    init() {
        if defaults.object(forKey: "musicEnabled") != nil {
            musicEnabled = defaults.bool(forKey: "musicEnabled")
        }
        if defaults.object(forKey: "sfxEnabled") != nil {
            sfxEnabled = defaults.bool(forKey: "sfxEnabled")
        }
        restoreBookmarks()
    }
    
    // MARK: - Persistència dels sons
    
    private func key(for slot: SoundSlot) -> String {
        "bookmark_\(slot.rawValue)"
    }
    
    private func restoreBookmarks() {
        for slot in SoundSlot.allCases {
            guard let data = defaults.data(forKey: key(for: slot)) else { continue }
            var stale = false
            do {
                let url = try URL(resolvingBookmarkData: data,
                                  options: [.withSecurityScope],
                                  relativeTo: nil,
                                  bookmarkDataIsStale: &stale)
                if url.startAccessingSecurityScopedResource() {
                    scopedURLs.insert(url)
                }
                soundURLs[slot] = url
                
                if stale,
                   let newData = try? url.bookmarkData(options: .withSecurityScope,
                                                       includingResourceValuesForKeys: nil,
                                                       relativeTo: nil) {
                    defaults.set(newData, forKey: key(for: slot))
                }
            } catch {
                print("⚠️ No s'ha pogut restaurar el so \(slot): \(error)")
            }
        }
    }
    
    /// Assigna un fitxer d'àudio a un moment del joc.
    func setSound(for slot: SoundSlot, from url: URL) {
        // Alliberem l'accés anterior
        if let old = soundURLs[slot], scopedURLs.contains(old) {
            old.stopAccessingSecurityScopedResource()
            scopedURLs.remove(old)
        }
        
        if url.startAccessingSecurityScopedResource() {
            scopedURLs.insert(url)
        }
        
        do {
            let bookmark = try url.bookmarkData(options: .withSecurityScope,
                                                includingResourceValuesForKeys: nil,
                                                relativeTo: nil)
            defaults.set(bookmark, forKey: key(for: slot))
            soundURLs[slot] = url
        } catch {
            print("⚠️ No s'ha pogut desar el bookmark: \(error)")
            return
        }
        
        if slot == .background {
            restartBackground()
        }
    }
    
    /// Treu el so assignat i en torna al per defecte.
    func removeSound(for slot: SoundSlot) {
        if let url = soundURLs[slot], scopedURLs.contains(url) {
            url.stopAccessingSecurityScopedResource()
            scopedURLs.remove(url)
        }
        soundURLs.removeValue(forKey: slot)
        defaults.removeObject(forKey: key(for: slot))

        if slot == .background {
            restartBackground()   // torna a la melodia per defecte
        }
    }
    
    // MARK: - Reproducció
    
    /// URL efectiva d'un moment del joc: el fitxer triat per l'usuari o,
    /// si no n'hi ha cap, el so per defecte sintetitzat pel propi joc.
    func effectiveURL(for slot: SoundSlot) -> URL {
        soundURLs[slot] ?? BuiltinSounds.url(for: slot)
    }
    
    /// Indica si l'usuari ha assignat un fitxer propi a aquest moment.
    func isCustom(_ slot: SoundSlot) -> Bool {
        soundURLs[slot] != nil
    }
    
    /// Arrenca la música de fons si està habilitada.
    func startBackgroundIfNeeded() {
        guard musicEnabled else { return }
        if musicPlayer == nil { restartBackground() } else { musicPlayer?.play() }
    }
    
    private func restartBackground() {
        musicPlayer?.stop()
        musicPlayer = nil
        guard musicEnabled else { return }
        let url = effectiveURL(for: .background)
        do {
            musicPlayer = try AVAudioPlayer(contentsOf: url)
            musicPlayer?.numberOfLoops = -1
            musicPlayer?.volume = soundURLs[.background] == nil ? 0.22 : 0.35
            musicPlayer?.prepareToPlay()
            musicPlayer?.play()
        } catch {
            print("⚠️ Error reproduint la música: \(error)")
        }
    }
    
    /// Reprodueix un efecte sonor.
    func playSFX(_ slot: SoundSlot) {
        guard sfxEnabled, !slot.isLoop else { return }
        let url = effectiveURL(for: slot)
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 0.6
            player.prepareToPlay()
            player.play()
            sfxPlayers.append(player)
            sfxPlayers.removeAll { !$0.isPlaying }
        } catch {
            print("⚠️ Error reproduint el so: \(error)")
        }
    }
    
    /// Reprodueix una previsualització (per al panell de configuració).
    func preview(_ slot: SoundSlot) {
        previewPlayer?.stop()
        let url = effectiveURL(for: slot)
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = slot.isLoop ? 0.35 : 0.6
            player.prepareToPlay()
            player.play()
            previewPlayer = player
            
            // Si és una pista llarga, l'aturem al cap de 5 segons
            if slot.isLoop {
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    player.stop()
                }
            }
        } catch {
            print("⚠️ Error previsualitzant: \(error)")
        }
    }
    
    // MARK: - Interruptors
    
    func toggleMusic() {
        musicEnabled.toggle()
        defaults.set(musicEnabled, forKey: "musicEnabled")
        if musicEnabled {
            startBackgroundIfNeeded()
        } else {
            musicPlayer?.pause()
        }
    }
    
    func toggleSFX() {
        sfxEnabled.toggle()
        defaults.set(sfxEnabled, forKey: "sfxEnabled")
    }
}
