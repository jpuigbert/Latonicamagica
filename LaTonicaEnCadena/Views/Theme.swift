import SwiftUI

enum Theme {
    static let rosa      = Color(red: 1.00, green: 0.75, blue: 0.85)
    static let rosaFort  = Color(red: 0.95, green: 0.45, blue: 0.65)
    static let lila      = Color(red: 0.85, green: 0.75, blue: 1.00)
    static let lilaFort  = Color(red: 0.55, green: 0.35, blue: 0.85)
    static let cel       = Color(red: 0.75, green: 0.90, blue: 1.00)
    
    /// Colors de tarjeta de jugador, per ordre (fins a 6 jugadors).
    static let paletaJugadors: [Color] = [
        rosaFort,
        lilaFort,
        Color(red: 0.30, green: 0.75, blue: 0.55),   // menta
        Color(red: 0.95, green: 0.65, blue: 0.20),   // daurat
        Color(red: 0.35, green: 0.65, blue: 0.95),   // blau cel
        Color(red: 0.75, green: 0.45, blue: 0.90)    // violeta
    ]
    
    static func color(for tipus: TipusTonica) -> Color {
        switch tipus {
        case .aguda:          return rosaFort
        case .plana:          return lilaFort
        case .esdruixola:     return Color(red: 0.30, green: 0.75, blue: 0.55)
        case .sobresdruixola: return Color(red: 0.95, green: 0.65, blue: 0.20)
        }
    }
    
    static func emoji(for tipus: TipusTonica) -> String {
        switch tipus {
        case .aguda:          return "🌸"
        case .plana:          return "🦄"
        case .esdruixola:     return "⭐️"
        case .sobresdruixola: return "🌈"
        }
    }
    
    static var fons: LinearGradient {
        LinearGradient(
            colors: [rosa.opacity(0.55), lila.opacity(0.55), cel.opacity(0.55)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
