import Foundation
import SwiftUI

enum SwipeDirection {
    case up, down, left, right
}

enum GameState {
    case playing, won, lost
}

class GameSettings: ObservableObject {
    @Published var boardSize: Int {
        didSet {
            if boardSize != oldValue {
                shouldResetGame = true
            }
        }
    }
    @Published var targetSum: Int {
        didSet {
            if targetSum != oldValue {
                shouldResetGame = true
            }
        }
    }
    @Published var shouldResetGame: Bool = false
    
    init(boardSize: Int = 4, targetSum: Int = 1024) {
        self.boardSize = boardSize
        self.targetSum = targetSum
    }
    
    func validateBoardSize(_ size: Int) -> Bool {
        return size >= 3 && size <= 7
    }
    
    func validateTargetSum(_ sum: Int) -> Bool {
        return sum > 0 && isPowerOfTwo(sum)
    }
    
    private func isPowerOfTwo(_ number: Int) -> Bool {
        number > 0 && (number & (number - 1)) == 0
    }
}
