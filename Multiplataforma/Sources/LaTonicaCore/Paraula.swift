import Foundation

public struct Paraula: Identifiable, Hashable, Codable {
    public let id: UUID
    public let text: String
    public let tipus: TipusTonica
    public let origen: Origen
    
    public enum Origen: String, Codable {
        case local
        case api
    }
    
    public init(id: UUID = UUID(), text: String, tipus: TipusTonica, origen: Origen = .local) {
        self.id = id
        self.text = text
        self.tipus = tipus
        self.origen = origen
    }
}
