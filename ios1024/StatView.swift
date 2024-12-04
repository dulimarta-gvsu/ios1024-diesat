import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class StatsViewModel: ObservableObject {
    @Published var gameStats: [GameStats] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    func loadStats(for userId: String) async {
        isLoading = true
        
        do {
            let snapshot = try await db.collection("players")
                .document(userId)
                .collection("games")
                .order(by: "timestamp", descending: true)
                .getDocuments()
                
            await MainActor.run {
                gameStats = snapshot.documents.compactMap { document in
                    try? document.data(as: GameStats.self)
                }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    func sortBySteps(ascending: Bool) {
        gameStats.sort { first, second in
            ascending ? first.steps < second.steps : first.steps > second.steps
        }
    }
    
    func sortByDate() {
        gameStats.sort { $0.timestamp > $1.timestamp }
    }
}

struct StatView: View {
    @StateObject private var statsViewModel = StatsViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var driver: MyNavigator
    
    var body: some View {
        VStack(spacing: 16) {
            if let profile = authViewModel.userProfile {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome, \(profile.realName)")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Total Games: \(profile.totalGames)")
                        .font(.headline)
                    
                    Text("Average Steps: \(String(format: "%.1f", profile.averageSteps))")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 8) {
                    Button("Steps ↑") {
                        statsViewModel.sortBySteps(ascending: true)
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Steps ↓") {
                        statsViewModel.sortBySteps(ascending: false)
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Date") {
                        statsViewModel.sortByDate()
                    }
                    .buttonStyle(.bordered)
                }
                
                if let error = statsViewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.callout)
                }
                
                if statsViewModel.isLoading {
                    ProgressView("Loading stats...")
                        .padding()
                } else if statsViewModel.gameStats.isEmpty {
                    Text("No games played yet")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(statsViewModel.gameStats, id: \.id) { stat in
                                GameStatCard(stat: stat)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            
            Button("Back to Game") {
                driver.backNav()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .task {
            if let userId = authViewModel.currentUser?.uid {
                await statsViewModel.loadStats(for: userId)
            }
        }
    }
}

struct GameStatCard: View {
    let stat: GameStats
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(stat.won ? "Victory!" : "Game Over")
                    .fontWeight(.bold)
                    .foregroundColor(stat.won ? .green : .red)
                
                Spacer()
                
                Text("Board: \(stat.boardSize)x\(stat.boardSize)")
            }
            
            HStack {
                Text("Steps: \(stat.steps)")
                Spacer()
                Text("Max Score: \(stat.maxScore)")
            }
            
            if stat.playTimeSeconds > 0 {
                Text("Time: \(timeString(from: stat.playTimeSeconds))")
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(stat.won ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(stat.won ? Color.green.opacity(0.3) : Color.red.opacity(0.3))
        )
    }
}

#Preview {
    StatView()
        .environmentObject(AuthViewModel())
        .environmentObject(MyNavigator())
}
