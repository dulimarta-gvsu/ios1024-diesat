import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: GameViewModel
    @EnvironmentObject var driver: MyNavigator
    
    @State private var selectedSize: Int
    @State private var targetSumText: String
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    init(viewModel: GameViewModel) {
        self.viewModel = viewModel
        _selectedSize = State(initialValue: viewModel.settings.boardSize)
        _targetSumText = State(initialValue: String(viewModel.settings.targetSum))
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Game Configuration")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Board Size")
                    .font(.headline)
                
                HStack(spacing: 8) {
                    ForEach(3...7, id: \.self) { size in
                        Button("\(size)x\(size)") {
                            selectedSize = size
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(selectedSize == size ? .blue : .gray)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Target Sum (must be a power of 2)")
                    .font(.headline)
                
                TextField("Enter target sum", text: $targetSumText)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .padding(.horizontal)
                
                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.callout)
                }
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button("Save & Return") {
                    if validateSettings() {
                        if viewModel.settings.validateBoardSize(selectedSize) {
                            viewModel.resizeGrid(to: selectedSize)  // Use the new resize method
                        }
                        if let targetSum = Int(targetSumText) {
                            viewModel.settings.targetSum = targetSum
                        }
                        driver.backNav()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Cancel") {
                    driver.backNav()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
    
    private func validateSettings() -> Bool {
        showError = false
        
        guard let targetSum = Int(targetSumText) else {
            errorMessage = "Please enter a valid number"
            showError = true
            return false
        }
        
        guard targetSum > 0 else {
            errorMessage = "Target sum must be positive"
            showError = true
            return false
        }
        
        guard isPowerOfTwo(targetSum) else {
            errorMessage = "Target sum must be a power of 2"
            showError = true
            return false
        }
        
        return true
    }
    
    private func isPowerOfTwo(_ number: Int) -> Bool {
        number > 0 && (number & (number - 1)) == 0
    }
}
