import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class GameViewModel: ObservableObject {
    @Published var grid: [[Int]]
    @Published var validSwipes: Int
    @Published var gameState: GameState
    @Published var settings: GameSettings
    private var gameStartTime: Date
    
    init() {
        self.settings = GameSettings()
        self.validSwipes = 0
        self.gameState = .playing
        self.grid = Array(repeating: Array(repeating: 0, count: GameSettings().boardSize),
                         count: GameSettings().boardSize)
        self.gameStartTime = Date()
        self.resetGame()
    }
    
    func resetGame() {
        gameStartTime = Date()
        let size = settings.boardSize
        self.grid = Array(repeating: Array(repeating: 0, count: size), count: size)
        validSwipes = 0
        gameState = .playing
        addNewNumber()
        addNewNumber()
    }

    func resizeGrid(to newSize: Int) {
        self.grid = Array(repeating: Array(repeating: 0, count: newSize), count: newSize)
        settings.boardSize = newSize
        resetGame()
    }
    
    func handleSwipe(_ direction: SwipeDirection) {
        guard gameState == .playing else { return }
        
        let oldGrid = grid
        
        switch direction {
        case .up: moveUp()
        case .down: moveDown()
        case .left: moveLeft()
        case .right: moveRight()
        }
        
        if grid != oldGrid {
            validSwipes += 1
            addNewNumber()
            checkGameStatus()
        }
    }
    
    private func moveLeft() {
        for i in 0..<settings.boardSize {
            var row = grid[i].filter { $0 != 0 }
            var j = 0
            while j < row.count - 1 {
                if row[j] == row[j + 1] {
                    row[j] *= 2
                    row.remove(at: j + 1)
                }
                j += 1
            }
            while row.count < settings.boardSize {
                row.append(0)
            }
            grid[i] = row
        }
    }
    
    private func moveRight() {
        for i in 0..<settings.boardSize {
            var row = grid[i].filter { $0 != 0 }
            var j = row.count - 1
            while j > 0 {
                if row[j] == row[j - 1] {
                    row[j] *= 2
                    row.remove(at: j - 1)
                    j -= 1
                }
                j -= 1
            }
            while row.count < settings.boardSize {
                row.insert(0, at: 0)
            }
            grid[i] = row
        }
    }
    
    private func moveUp() {
        for j in 0..<settings.boardSize {
            var col = (0..<settings.boardSize).map { grid[$0][j] }.filter { $0 != 0 }
            var i = 0
            while i < col.count - 1 {
                if col[i] == col[i + 1] {
                    col[i] *= 2
                    col.remove(at: i + 1)
                }
                i += 1
            }
            while col.count < settings.boardSize {
                col.append(0)
            }
            for i in 0..<settings.boardSize {
                grid[i][j] = col[i]
            }
        }
    }
    
    private func moveDown() {
        for j in 0..<settings.boardSize {
            var col = (0..<settings.boardSize).map { grid[$0][j] }.filter { $0 != 0 }
            var i = col.count - 1
            while i > 0 {
                if col[i] == col[i - 1] {
                    col[i] *= 2
                    col.remove(at: i - 1)
                    i -= 1
                }
                i -= 1
            }
            while col.count < settings.boardSize {
                col.insert(0, at: 0)
            }
            for i in 0..<settings.boardSize {
                grid[i][j] = col[i]
            }
        }
    }
    
    private func addNewNumber() {
        var emptyCells = [(Int, Int)]()
        for i in 0..<settings.boardSize {
            for j in 0..<settings.boardSize {
                if grid[i][j] == 0 {
                    emptyCells.append((i, j))
                }
            }
        }
        
        guard let (randomRow, randomCol) = emptyCells.randomElement() else { return }
        let random = Double.random(in: 0...1)
        let value = random <= 0.6 ? 2 : (random <= 0.9 ? 4 : 8)
        grid[randomRow][randomCol] = value
    }
    
    private func checkGameStatus() {
        let oldStatus = gameState
        
        if grid.contains(where: { row in row.contains(where: { $0 >= settings.targetSum })}) {
            gameState = .won
        } else if !canMove() {
            gameState = .lost
        }
        
        if oldStatus == .playing && gameState != .playing {
            saveGameStats(won: gameState == .won)
        }
    }
    
    private func canMove() -> Bool {
        let size = settings.boardSize
        
        if grid.contains(where: { row in row.contains(0) }) {
            return true
        }
        
        for i in 0..<size {
            for j in 0..<size {
                let current = grid[i][j]
                
                if j < size - 1 && current == grid[i][j + 1] {
                    return true
                }
                if i < size - 1 && current == grid[i + 1][j] {
                    return true
                }
            }
        }
        return false
    }
}

extension GameViewModel {
    func saveGameStats(won: Bool) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let gameStats = GameStats(
            steps: validSwipes,
            boardSize: settings.boardSize,
            won: won,
            maxScore: grid.flatMap { $0 }.max() ?? 0,
            timestamp: Date(),
            playTimeSeconds: Int(Date().timeIntervalSince(gameStartTime))
        )
        
        Task {
            do {
                let docRef = try await db.collection("players")
                    .document(userId)
                    .collection("games")
                    .addDocument(from: gameStats)
                
                let gamesSnapshot = try await db.collection("players")
                    .document(userId)
                    .collection("games")
                    .getDocuments()
                
                let totalGames = gamesSnapshot.documents.count
                
                let allGames = gamesSnapshot.documents.compactMap { doc -> GameStats? in
                    try? doc.data(as: GameStats.self)
                }
                
                let totalSteps = allGames.reduce(0) { $0 + $1.steps }
                let averageSteps = Double(totalSteps) / Double(totalGames)
                
                try await db.collection("players")
                    .document(userId)
                    .setData([
                        "totalGames": totalGames,
                        "averageSteps": averageSteps
                    ], merge: true)
                
            } catch {
                print("Error saving game stats: \(error.localizedDescription)")
            }
        }
    }
}
