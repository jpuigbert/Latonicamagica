import Foundation
// Quan es compila amb SPM (Linux/Windows) el nucli és un mòdul; quan es
// compila tot junt amb swiftc (script del Mac) els tipus ja són al mateix
// mòdul principal.
#if canImport(LaTonicaCore)
import LaTonicaCore
#endif

// MARK: - La Tònica Màgica — versió de terminal (Linux / Windows / macOS)
// Només usa Foundation, de manera que es compila amb el Swift Toolchain
// oficial en qualsevol plataforma.

func neteja(_ s: String) -> String {
    s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
}

let tipus = TipusTonica.allCases   // 1 aguda, 2 plana, 3 esdruixola, 4 sobresdrúixola

print("┌─────────────────────────────────────┐")
print("│   🦄  LA TÒNICA MÀGICA  🦄           │")
print("│        (versió de text)              │")
print("└─────────────────────────────────────┘")
print("")
print("Endevina on sona més fort la paraula:")
for (i, t) in tipus.enumerated() {
    print("  \(i + 1)) \(t.rawValue) — \(t.explicacio)")
}
print("")
print("Respon amb 1-4. Altres ordres: 'p' puntuació, 's' sortir.")
print("")

var puntuacio = 0
var encerts = 0
var falles = 0
var usades = Set<UUID>()

buclePrincipal: while true {
    var disponibles = DiccionariLocal.totes.filter { !usades.contains($0.id) }
    if disponibles.isEmpty {
        usades.removeAll()
        disponibles = DiccionariLocal.totes
    }
    guard let paraula = disponibles.randomElement() else { break }
    usades.insert(paraula.id)

    print("Paraula: «\(paraula.text)»  →  ")
    guard let linia = readLine() else { break }
    let resposta = neteja(linia)

    switch resposta {
    case "s", "sortir", "quit", "exit":
        print("Puntuació final: \(puntuacio) ⭐  (\(encerts) encerts, \(falles) falles)")
        print("Fins a la propera! 🌈")
        break buclePrincipal
    case "p":
        print("   puntuació: \(puntuacio) ⭐  (\(encerts) encerts, \(falles) falles)")
        continue
    default:
        break
    }

    guard let num = Int(resposta), num >= 1, num <= tipus.count else {
        print("   (Posa un número de l'1 al 4, 'p' o 's'.)")
        usades.remove(paraula.id)   // la tornarem a tenir disponible
        continue
    }

    let triat = tipus[num - 1]
    if triat == paraula.tipus {
        puntuacio += 1
        encerts += 1
        print("   🌟 Molt bé! \(paraula.text) és \(triat.rawValue.lowercased()).")
    } else {
        falles += 1
        print("   💭 Gairebé! \(paraula.text) és \(paraula.tipus.rawValue.lowercased()) perquè \(paraula.tipus.explicacio).")
    }
    print("")
}
