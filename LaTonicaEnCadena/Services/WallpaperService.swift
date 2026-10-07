import AppKit
import Combine
import Foundation

/// Gestiona la imatge de fons (wallpaper) triada per l'usuari.
/// La imatge es COPIA a l'Application Support del joc, perquè segueixi
/// disponible encara que la carpeta original es mogui o calguin permisos.
final class WallpaperService: ObservableObject {

    static let shared = WallpaperService()

    @Published private(set) var image: NSImage?
    @Published private(set) var fileURL: URL?

    private let defaults = UserDefaults.standard
    private let key = "wallpaper_path"

    private var dir: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                            in: .userDomainMask)[0]
        return base.appendingPathComponent("LaTonicaEnCadena", isDirectory: true)
    }

    private init() {
        if let p = defaults.string(forKey: key) {
            let url = URL(fileURLWithPath: p)
            if let img = NSImage(contentsOf: url) {
                fileURL = url
                image = img
            }
        }
    }

    /// Copia la imatge escollida i l'activa com a fons.
    func setWallpaper(from src: URL) {
        let ext = src.pathExtension.lowercased()
        let dest = dir.appendingPathComponent("wallpaper.\(ext.isEmpty ? "png" : ext)")
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.removeItem(at: dest)
            }
            try FileManager.default.copyItem(at: src, to: dest)
            guard let img = NSImage(contentsOf: dest) else {
                print("⚠️ El fitxer no és una imatge llegible: \(src.path)")
                return
            }
            // Esborra la còpia anterior si en canviem l'extensió
            if let old = fileURL, old != dest {
                try? FileManager.default.removeItem(at: old)
            }
            image = img
            fileURL = dest
            defaults.set(dest.path, forKey: key)
        } catch {
            print("⚠️ Error copejant el fons de pantalla: \(error)")
        }
    }

    /// Torna al degradat pastel per defecte del joc.
    func removeWallpaper() {
        if let url = fileURL {
            try? FileManager.default.removeItem(at: url)
        }
        fileURL = nil
        image = nil
        defaults.removeObject(forKey: key)
    }
}
