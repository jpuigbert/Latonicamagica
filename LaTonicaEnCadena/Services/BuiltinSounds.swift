import Foundation

/// Genera els sons per defecte del joc sintetitzant-los en memòria i
/// guardant-los com a fitxers WAV dins de ~/Library/Application Support.
/// Així el joc té música i efectes des de la primera arrencada, sense que
/// l'usuari hagi de triar cap fitxer.
enum BuiltinSounds {

    private static let sampleRate = 44100.0

    private static var dir: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                            in: .userDomainMask)[0]
        return base.appendingPathComponent("LaTonicaEnCadena/SonsPerDefecte", isDirectory: true)
    }

    /// URL del so per defecte d'un moment del joc.
    /// Crea el fitxer WAV la primera vegada que calgui.
    static func url(for slot: SoundSlot) -> URL {
        let file = dir.appendingPathComponent("\(slot.rawValue).wav")
        if !FileManager.default.fileExists(atPath: file.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            if let data = wavData(for: slot) {
                try? data.write(to: file)
            }
        }
        return file
    }

    // MARK: - Generació de cada pista

    private static func wavData(for slot: SoundSlot) -> Data? {
        switch slot {
        case .background:
            return pcmWav(musicaDeFons())
        case .correct:    // arpeggio ascendente brillant: "has encertat!"
            return pcmWav(sequencia([523.25, 659.25, 783.99, 1046.5],
                                    notaDur: 0.11, amp: 0.55, decay: 5.0))
        case .wrong:      // dues notes descendents, tovals i no agressius
            return pcmWav(sequencia([392.0, 311.13],
                                    notaDur: 0.22, amp: 0.45, decay: 3.5))
        case .turn:       // "blip" curt de canvi de torn
            return pcmWav(sequencia([880.0, 1318.5],
                                    notaDur: 0.07, amp: 0.40, decay: 8.0))
        case .reset:      // escombrat ascendent en reiniciar
            return pcmWav(sequencia([440.0, 554.37, 659.25, 880.0],
                                    notaDur: 0.09, amp: 0.45, decay: 6.0))
        }
    }

    /// Successió de notes concatenades (so de campana suau).
    private static func sequencia(_ freqs: [Double], notaDur: Double,
                                  amp: Double, decay: Double) -> [Float] {
        var out = [Float](repeating: 0, count: 0)
        for f in freqs {
            out += nota(frequency: f, duration: notaDur * 2.4,
                        amplitude: amp, decay: decay)
        }
        return normalitzat(out, pic: 0.6)
    }

    /// Música de fons: loop de pentatònica somiant amb eco i bordó greu.
    private static func musicaDeFons() -> [Float] {
        let melodia: [Double] = [
            261.63, 329.63, 392.0,  440.0, 523.25, 440.0, 392.0, 329.63,
            293.66, 349.23, 440.0, 523.25, 587.33, 523.25, 440.0, 349.23
        ]
        let notaDur = 0.42
        let total = Int(Double(melodia.count) * notaDur * sampleRate) + 22_050 // cua per l'eco
        var out = [Float](repeating: 0, count: total)

        for (i, f) in melodia.enumerated() {
            let inici = Int(Double(i) * notaDur * sampleRate)
            afegeixNota(frequency: f, duration: notaDur * 2.6,
                        amplitude: 0.30, decay: 3.2, at: inici, into: &out)
            // Eco una octava més amunt, fluix
            let eco = inici + Int(0.21 * sampleRate)
            if eco < total {
                afegeixNota(frequency: f * 2, duration: notaDur * 1.6,
                            amplitude: 0.08, decay: 5.0, at: eco, into: &out)
            }
        }
        // Bordó greu que manté el to durant tot el loop
        afegeixNota(frequency: 130.81, duration: Double(total) / sampleRate,
                    amplitude: 0.10, decay: 0.25, at: 0, into: &out)

        return normalitzat(out, pic: 0.45)
    }

    // MARK: - Sintetitzadors baixos

    private static func nota(frequency f: Double, duration d: Double,
                             amplitude a: Double, decay: Double) -> [Float] {
        let n = max(Int(d * sampleRate), 0)
        var samples = [Float](repeating: 0, count: n)
        afegeixNota(frequency: f, duration: d, amplitude: a, decay: decay,
                    at: 0, into: &samples)
        return samples
    }

    private static func afegeixNota(frequency f: Double, duration d: Double,
                                    amplitude a: Double, decay: Double,
                                    at inici: Int, into buf: inout [Float]) {
        let n = min(Int(d * sampleRate), buf.count - inici)
        guard n > 0 else { return }
        for j in 0..<n {
            let t = Double(j) / sampleRate
            buf[inici + j] += Float(a * envoluent(t, decay: decay) * ona(f, t))
        }
    }

    /// Atac ràpid + decaïment exponencial.
    private static func envoluent(_ t: Double, decay: Double) -> Double {
        exp(-decay * t) * min(1.0, t / 0.006)
    }

    /// Ona amb harmònics per sonar més càlida que un sinusoide pur.
    private static func ona(_ f: Double, _ t: Double) -> Double {
        sin(2 * .pi * f * t) + 0.3 * sin(4 * .pi * f * t) + 0.1 * sin(6 * .pi * f * t)
    }

    private static func normalitzat(_ samples: [Float], pic: Double) -> [Float] {
        let maxAbs = samples.map { abs($0) }.max() ?? 0
        guard maxAbs > 0 else { return samples }
        let g = Float(pic / Double(maxAbs))
        return samples.map { $0 * g }
    }

    // MARK: - Contenidor WAV (16-bit PCM mono)

    private static func pcmWav(_ samples: [Float]) -> Data {
        var pcm = Data(capacity: samples.count * 2)
        for s in samples {
            let v = Int16(max(-1.0, min(1.0, Double(s))) * 32767.0)
            var le = v.littleEndian
            withUnsafeBytes(of: &le) { pcm.append(contentsOf: $0) }
        }

        var data = Data()
        func ascii(_ s: String) { data.append(contentsOf: s.utf8) }
        func u32(_ v: UInt32) { var le = v.littleEndian; withUnsafeBytes(of: &le) { data.append(contentsOf: $0) } }
        func u16(_ v: UInt16) { var le = v.littleEndian; withUnsafeBytes(of: &le) { data.append(contentsOf: $0) } }

        ascii("RIFF"); u32(UInt32(36 + pcm.count)); ascii("WAVE")
        ascii("fmt "); u32(16)
        u16(1)                          // PCM
        u16(1)                          // mono
        u32(UInt32(sampleRate))
        u32(UInt32(sampleRate) * 2)     // byte rate
        u16(2)                          // block align
        u16(16)                         // bits
        ascii("data"); u32(UInt32(pcm.count))
        data.append(pcm)
        return data
    }
}
