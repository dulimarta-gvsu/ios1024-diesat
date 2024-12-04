import SwiftUI
enum Destination{
    case LoginDestination
    case NewAccountDestination
    case GameDestination
    case SettingsDestination
    case StatisticsDestination
}
class MyNavigator: ObservableObject{
    @Published var navPath: NavigationPath =
        NavigationPath()
    
    func navigate (to d: Destination){
        navPath.append(d)
    }
    func backHome(){
        while navPath.count > 0 {
            navPath.removeLast()
        }
    }
    
    func backNav(){
        navPath.removeLast()
    }
}
