import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var userProfile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var stateListener: AuthStateDidChangeListenerHandle?
    
    init() {
        currentUser = auth.currentUser
        setupAuthListener()
    }
    
    private func setupAuthListener() {
        stateListener = auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                if let user = user {
                    // Only try to load profile for logged in users
                    try? await self?.loadUserProfile(userId: user.uid)
                } else {
                    self?.userProfile = nil
                    self?.errorMessage = nil
                }
            }
        }
    }
    
    deinit {
        if let listener = stateListener {
            auth.removeStateDidChangeListener(listener)
        }
    }
    
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            currentUser = result.user
            try? await loadUserProfile(userId: result.user.uid)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func createAccount(email: String, password: String, realName: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            
            let userProfile = UserProfile(
                id: result.user.uid,
                email: email,
                realName: realName,
                totalGames: 0,
                averageSteps: 0
            )
            
            let userData: [String: Any] = [
                "uid": result.user.uid,
                "email": email,
                "realName": realName,
                "totalGames": 0,
                "averageSteps": 0.0
            ]
            
            try await db.collection("players")
                .document(result.user.uid)
                .setData(userData)
            
            currentUser = result.user
            self.userProfile = userProfile
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signOut() {
        do {
            try auth.signOut()
            currentUser = nil
            userProfile = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func loadUserProfile(userId: String) async throws {
        let documentSnapshot = try await db.collection("players")
            .document(userId)
            .getDocument()
        
        if documentSnapshot.exists {
            if let data = documentSnapshot.data() {
                self.userProfile = UserProfile(
                    id: userId,
                    email: data["email"] as? String ?? "",
                    realName: data["realName"] as? String ?? "",
                    totalGames: data["totalGames"] as? Int ?? 0,
                    averageSteps: data["averageSteps"] as? Double ?? 0.0
                )
            }
        }
    }
}
