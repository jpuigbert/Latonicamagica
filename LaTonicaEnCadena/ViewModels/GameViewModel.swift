import Foundation
import Combine

@MainActor
final class GameViewModel: ObservableObject {
    
    // MARK: - Estat publicat
    
    @Published private(set) var players: [Player] = []
    @Published private(set) var currentPlayerIndex: Int = 0
    @Published private(set) var currentWord: Paraula?
    @Published var selectedTipus: TipusTonica?
    @Published private(set) var feedback: String = ""
    @Published private(set) var feedbackCorrecte: Bool = false
    @Published private(set) var isAnswered: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published var useAPI: Bool = false {
        didSet { if useAPI != oldValue { nextWord() } }
    }
    
    // MARK: - Dependències
    
    let music: MusicService
    private let diccionariLocal: [Paraula]
    private let service: DictionaryService
    private var usedWords: Set<UUID> = []
    
    private let candidatesAPI = [
        "música", "casa", "camí", "ràpidament", "llibre",
        "pàgina", "problema", "examen", "història", "telèfon"
    ]
    
    /// Noms temàtics per als jugadors, en ordre d'aparició.
    private let nomsMagic = [
        "Fada 🌸", "Unicorni 🦄", "Sirena 🧜‍♀️",
        "Drac 🐉", "Gnomo 🍄", "Estrella ⭐"
    ]
    
    static let minimJugadors = 1
    static let maximJugadors = 6
    
    // MARK: - Inicialització
    
    init(diccionari: [Paraula] = DiccionariLocal.totes,
         service: DictionaryService = DictionaryService(),
         music: MusicService? = nil) {
        self.diccionariLocal = diccionari
        self.service = service
        // MusicService es @MainActor: el construim aqui (dins del cos de
        // l'init, aillat al main actor) i no com a argument per defecte, que
        // s'avaluaria en un context no-isolat.
        self.music = music ?? MusicService()
        setupPlayers()
        self.music.startBackgroundIfNeeded()
        nextWord()
    }
    
    private func setupPlayers() {
        players = nomsMagic.prefix(2).map { Player(name: $0) }
    }
    
    var currentPlayer: Player { players[currentPlayerIndex] }
    
    // MARK: - Gestió de jugadors
    
    var potAfegirJugador: Bool { players.count < Self.maximJugadors }
    var potTreureJugador: Bool { players.count > Self.minimJugadors }
    
    /// Afegeix un jugador nou (fins a 6) amb el primer nom lliure.
    func addPlayer() {
        guard potAfegirJugador else { return }
        let usats = Set(players.map(\.name))
        let nom = nomsMagic.first { !usats.contains($0) }
            ?? "Jugador \(players.count + 1) 🎈"
        players.append(Player(name: nom))
    }
    
    /// Treu l'últim jugador (mai per sota de 1) i reajusta el torn.
    func removePlayer() {
        guard potTreureJugador else { return }
        players.removeLast()
        if currentPlayerIndex >= players.count {
            currentPlayerIndex = 0
        }
    }
    
    // MARK: - Càrrega de paraules
    
    func nextWord() {
        if useAPI {
            Task { await loadWordFromAPI() }
        } else {
            loadWordFromLocal()
        }
    }
    
    private func loadWordFromLocal() {
        var available = diccionariLocal.filter { !usedWords.contains($0.id) }
        if available.isEmpty {
            usedWords.removeAll()
            available = diccionariLocal
        }
        guard let word = available.randomElement() else { return }
        usedWords.insert(word.id)
        currentWord = word
        resetRound()
    }
    
    private func loadWordFromAPI() async {
        isLoading = true
        resetRound()
        
        guard let candidate = candidatesAPI.randomElement() else {
            isLoading = false
            return
        }
        
        do {
            let word = try await service.fetchAndClassify(candidate)
            currentWord = word
        } catch {
            feedback = "⚠️ No s'ha pogut connectar a Internet. Es carrega una paraula del joc."
            feedbackCorrecte = false
            loadWordFromLocal()
        }
        isLoading = false
    }
    
    private func resetRound() {
        selectedTipus = nil
        feedback = ""
        feedbackCorrecte = false
        isAnswered = false
    }
    
    // MARK: - Validació
    
    func checkAnswer() {
        guard let word = currentWord, let selected = selectedTipus else { return }
        isAnswered = true
        
        if selected == word.tipus {
            players[currentPlayerIndex].score += 1
            feedback = "Molt bé, \(currentPlayer.name)! Has encertat! 🌟"
            feedbackCorrecte = true
            music.playSFX(.correct)
        } else {
            feedback = """
            Gairebé! 😊 La paraula «\(word.text)» és \(word.tipus.rawValue.lowercased()) \
            perquè \(word.tipus.explicacio).
            """
            feedbackCorrecte = false
            music.playSFX(.wrong)
        }
    }
    
    func advanceTurn() {
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
        music.playSFX(.turn)
        nextWord()
    }
    
    func resetGame() {
        for i in players.indices {
            players[i].score = 0
        }
        currentPlayerIndex = 0
        usedWords.removeAll()
        service.clearCache()
        music.playSFX(.reset)
        nextWord()
    }
}
