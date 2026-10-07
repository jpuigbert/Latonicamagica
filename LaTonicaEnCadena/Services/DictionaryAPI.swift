import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case wordNotFound
    case decodingError
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:            return "URL de l'API no vàlida."
        case .wordNotFound:          return "Paraula no trobada al diccionari."
        case .decodingError:         return "Error al processar la resposta."
        case .networkError(let err): return "Error de xarxa: \(err.localizedDescription)"
        }
    }
}

final class DictionaryAPI {
    private let baseURL = "https://api.dictionaryapi.dev/api/v2/entries/ca"
    
    func lookup(word: String) async throws -> [APIWordResponse] {
        guard let encoded = word.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(baseURL)/\(encoded)") else {
            throw APIError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let http = response as? HTTPURLResponse else {
                throw APIError.decodingError
            }
            guard http.statusCode == 200 else {
                throw APIError.wordNotFound
            }
            
            return try JSONDecoder().decode([APIWordResponse].self, from: data)
        } catch let error as APIError {
            throw error
        } catch is DecodingError {
            throw APIError.decodingError
        } catch {
            throw APIError.networkError(error)
        }
    }
}
