import SwiftUI

struct GameView: View {
    @ObservedObject var viewModel: GameViewModel
    @EnvironmentObject var driver: MyNavigator
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Welcome to 1024!")
                .font(.title2)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Target: \(viewModel.settings.targetSum)")
                        .font(.headline)
                    Text("Moves: \(viewModel.validSwipes)")
                        .font(.headline)
                }
                
                Spacer()
                
                Button("Settings") {
                    driver.navigate(to: .SettingsDestination)
                }
                .buttonStyle(.borderedProminent)
            }
            
            ZStack {
                NumberGrid(viewModel: viewModel)
                    .gesture(
                        DragGesture()
                            .onEnded { gesture in
                                if viewModel.gameState == .playing {
                                    let direction = determineSwipeDirection(gesture)
                                    viewModel.handleSwipe(direction)
                                }
                            }
                    )
                
                if viewModel.gameState != .playing {
                    GameOverlay(
                        gameState: viewModel.gameState,
                        moves: viewModel.validSwipes,
                        onReset: { viewModel.resetGame() }
                    )
                }
            }
            
            Button("Reset Game") {
                viewModel.resetGame()
            }
            .buttonStyle(.borderedProminent)
            
            Button("Logout") {
                driver.backHome()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding()
        .onChange(of: viewModel.settings.shouldResetGame) { oldValue, newValue in
            if newValue {
                viewModel.resetGame()
                viewModel.settings.shouldResetGame = false
            }
        }
    }
    
    private func determineSwipeDirection(_ gesture: DragGesture.Value) -> SwipeDirection {
        let horizontalAmount = gesture.translation.width
        let verticalAmount = gesture.translation.height
        
        if abs(horizontalAmount) > abs(verticalAmount) {
            return horizontalAmount < 0 ? .left : .right
        } else {
            return verticalAmount < 0 ? .up : .down
        }
    }
}

struct NumberGrid: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 4),
                         count: viewModel.settings.boardSize),
            spacing: 4
        ) {
            ForEach(0..<viewModel.settings.boardSize, id: \.self) { row in
                ForEach(0..<viewModel.settings.boardSize, id: \.self) { column in
                    NumberCell(number: viewModel.grid[row][column])
                }
            }
        }
        .padding(4)
        .background(Color.gray.opacity(0.3))
        .cornerRadius(8)
    }
}

struct NumberCell: View {
    let number: Int
    
    private var backgroundColor: Color {
        switch number {
        case 0: return Color.gray.opacity(0.2)
        case 2: return Color(red: 0.93, green: 0.89, blue: 0.85)
        case 4: return Color(red: 0.93, green: 0.88, blue: 0.78)
        case 8: return Color(red: 0.95, green: 0.69, blue: 0.47)
        case 16: return Color(red: 0.96, green: 0.58, blue: 0.39)
        case 32: return Color(red: 0.96, green: 0.49, blue: 0.37)
        case 64: return Color(red: 0.96, green: 0.37, blue: 0.23)
        case 128: return Color(red: 0.93, green: 0.81, blue: 0.45)
        case 256: return Color(red: 0.93, green: 0.80, blue: 0.38)
        case 512: return Color(red: 0.93, green: 0.78, blue: 0.31)
        case 1024: return Color(red: 0.93, green: 0.77, blue: 0.25)
        default: return Color(red: 0.93, green: 0.76, blue: 0.18)
        }
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(backgroundColor)
                .aspectRatio(1, contentMode: .fit)
                .cornerRadius(8)
            
            if number != 0 {
                Text("\(number)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(number <= 4 ? .black : .white)
            }
        }
    }
}

struct GameOverlay: View {
    let gameState: GameState
    let moves: Int
    let onReset: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
            
            VStack(spacing: 16) {
                Text(gameState == .won ?
                     "Congratulations!\nYou Won!" :
                     "Game Over!\nYou Lost!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Final Score: \(moves) moves")
                    .font(.title2)
                    .foregroundColor(.white)
                
                Button("Play Again") {
                    onReset()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)
            }
            .padding()
        }
        .ignoresSafeArea()
    }
}

#Preview {
    GameView(viewModel: GameViewModel())
        .environmentObject(MyNavigator())
}
