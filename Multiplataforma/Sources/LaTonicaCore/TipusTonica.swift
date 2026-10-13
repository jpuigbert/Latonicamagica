import Foundation

public enum TipusTonica: String, CaseIterable, Identifiable, Codable {
    case aguda = "Aguda"
    case plana = "Plana"
    case esdruixola = "Esdrúixola"
    case sobresdruixola = "Sobresdrúixola"
    
    public var id: String { rawValue }
    
    public var explicacio: String {
        switch self {
        case .aguda:          return "la síl·laba tònica és l'última"
        case .plana:          return "la síl·laba tònica és la penúltima"
        case .esdruixola:     return "la síl·laba tònica és l'antepenúltima"
        case .sobresdruixola: return "la síl·laba tònica va abans de l'antepenúltima"
        }
    }
}
