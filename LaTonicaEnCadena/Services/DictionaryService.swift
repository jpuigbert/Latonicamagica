import Foundation

final class DictionaryService {
    
    private let api: DictionaryAPI
    private var cache: [String: TipusTonica] = [:]
    
    init(api: DictionaryAPI = DictionaryAPI()) {
        self.api = api
    }
    
    func fetchAndClassify(_ word: String) async throws -> Paraula {
        if let cached = cache[word.lowercased()] {
            return Paraula(text: word, tipus: cached, origen: .api)
        }
        
        let responses = try await api.lookup(word: word)
        
        let tipus: TipusTonica
        if let phonetic = responses.first?.phonetic, !phonetic.isEmpty {
            tipus = classifyFromPhonetic(phonetic, word: word)
        } else {
            tipus = classifyHeuristic(word)
        }
        
        cache[word.lowercased()] = tipus
        return Paraula(text: word, tipus: tipus, origen: .api)
    }
    
    private func classifyFromPhonetic(_ phonetic: String, word: String) -> TipusTonica {
        guard let stressIndex = phonetic.firstIndex(of: "ˈ") else {
            return classifyHeuristic(word)
        }
        let afterStress = phonetic[phonetic.index(after: stressIndex)...]
        let separadors = afterStress.filter { $0 == "." }.count
        
        switch separadors {
        case 0:  return .aguda
        case 1:  return .plana
        case 2:  return .esdruixola
        default: return .sobresdruixola
        }
    }
    
    private func classifyHeuristic(_ word: String) -> TipusTonica {
        let lower = word.lowercased()
        
        if lower.hasSuffix("ment") && lower.count > 5 {
            return .sobresdruixola
        }
        
        let vocals: Set<Character> = ["a", "e", "i", "o", "u",
                                      "à", "è", "é", "í", "ò", "ó", "ú", "ü"]
        let count = lower.filter { vocals.contains($0) }.count
        
        switch count {
        case 0, 1: return .aguda
        case 2: return lower.hasSuffix("a") || lower.hasSuffix("e") ? .plana : .aguda
        default:
            if lower.hasSuffix("a") || lower.hasSuffix("e") || lower.hasSuffix("o") {
                return .plana
            }
            return .aguda
        }
    }
    
    func clearCache() {
        cache.removeAll()
    }
}
