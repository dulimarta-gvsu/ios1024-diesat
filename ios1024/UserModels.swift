import Foundation
import FirebaseFirestore

struct UserProfile: Codable, Identifiable {
    @DocumentID var id: String?
    let email: String
    let realName: String
    var totalGames: Int
    var averageSteps: Double
    
    enum CodingKeys: String, CodingKey {
        case id = "uid"  // Map 'id' to 'uid' in Firestore
        case email
        case realName
        case totalGames
        case averageSteps
    }
    
    init(id: String? = nil, email: String = "", realName: String = "", totalGames: Int = 0, averageSteps: Double = 0.0) {
        self.id = id
        self.email = email
        self.realName = realName
        self.totalGames = totalGames
        self.averageSteps = averageSteps
    }
}

struct GameStats: Codable, Identifiable {
    @DocumentID var id: String?
    let steps: Int
    let boardSize: Int
    let won: Bool
    let maxScore: Int
    let timestamp: Date
    let playTimeSeconds: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case steps
        case boardSize
        case won
        case maxScore
        case timestamp
        case playTimeSeconds
    }
    
    init(id: String? = nil,
         steps: Int = 0,
         boardSize: Int = 4,
         won: Bool = false,
         maxScore: Int = 0,
         timestamp: Date = Date(),
         playTimeSeconds: Int = 0) {
        self.id = id
        self.steps = steps
        self.boardSize = boardSize
        self.won = won
        self.maxScore = maxScore
        self.timestamp = timestamp
        self.playTimeSeconds = playTimeSeconds
    }
}
