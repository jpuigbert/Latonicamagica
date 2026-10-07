import Foundation

struct Paraula: Identifiable, Hashable, Codable {
    let id: UUID
    let text: String
    let tipus: TipusTonica
    let origen: Origen
    
    enum Origen: String, Codable {
        case local
        case api
    }
    
    init(id: UUID = UUID(), text: String, tipus: TipusTonica, origen: Origen = .local) {
        self.id = id
        self.text = text
        self.tipus = tipus
        self.origen = origen
    }
}
