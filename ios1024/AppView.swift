import SwiftUI

struct AppView: View {
    @ObservedObject private var navCtrl: MyNavigator = MyNavigator()
    @StateObject private var gameViewModel = GameViewModel()
    
    var body: some View {
        NavigationStack(path: $navCtrl.navPath) {
            LoginView()
                .navigationDestination(for: Destination.self) { d in
                    switch(d) {
                    case .GameDestination:
                        GameView(viewModel: gameViewModel)
                            .navigationBarBackButtonHidden(true)
                    case .NewAccountDestination:
                        NewAcctView()
                    case .SettingsDestination:
                        SettingsView(viewModel: gameViewModel)
                    case .StatisticsDestination:
                        StatView()
                    case .LoginDestination:
                        Text("This should not happen")
                    }
                }
        }
        .environmentObject(navCtrl)
    }
}
