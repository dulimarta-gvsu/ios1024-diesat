import SwiftUI

struct NewAcctView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @EnvironmentObject var driver: MyNavigator
    
    @State private var email = ""
    @State private var realName = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    private var passwordsMatch: Bool {
        !password.isEmpty && password == confirmPassword
    }
    
    private var isValidInput: Bool {
        !email.isEmpty && !realName.isEmpty &&
        !password.isEmpty && !confirmPassword.isEmpty &&
        passwordsMatch && !authViewModel.isLoading
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Create Account")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                TextField("Your Name", text: $realName)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.name)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.newPassword)
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.newPassword)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(!passwordsMatch && !confirmPassword.isEmpty ? Color.red : Color.clear)
                    )
            }
            .padding(.horizontal)
            
            if !passwordsMatch && !confirmPassword.isEmpty {
                Text("Passwords do not match")
                    .foregroundColor(.red)
                    .font(.callout)
            }
            
            if let error = authViewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.callout)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Button {
                    Task {
                        await authViewModel.createAccount(
                            email: email,
                            password: password,
                            realName: realName
                        )
                        if authViewModel.currentUser != nil {
                            driver.navigate(to: .GameDestination)
                        }
                    }
                } label: {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Create Account")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValidInput)
                
                Button("Cancel") {
                    driver.backNav()
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}
