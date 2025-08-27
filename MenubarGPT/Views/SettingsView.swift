import SwiftUI

/// Settings and configuration view
struct SettingsView: View {
    @EnvironmentObject private var openAIClient: OpenAIClient
    @Environment(\.settings) private var currentSettings
    @Environment(\.dismiss) private var dismiss
    
    @State private var settings: Settings
    @State private var apiKey = ""
    @State private var isTestingApiKey = false
    @State private var apiKeyTestResult: ApiKeyTestResult?
    @State private var showingApiKeyField = false
    @FocusState private var isApiKeyFieldFocused: Bool
    
    enum ApiKeyTestResult {
        case success
        case failure(String)
    }
    
    init() {
        _settings = State(initialValue: Settings.load())
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "gear")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Done") {
                    saveSettingsAndDismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Settings content
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // API Key Section
                    apiKeySection
                    
                    Divider()
                        .padding(.horizontal, -20)
                    
                    // Model Selection
                    modelSelectionSection
                    
                    Divider()
                        .padding(.horizontal, -20)
                    
                    // About
                    aboutSection
                }
                .padding(20)
            }
            .background(Color(NSColor.textBackgroundColor))
        }
        .frame(minWidth: 480, minHeight: 400)
        .onAppear {
            loadCurrentApiKey()
        }
    }
    
    // MARK: - API Key Section
    
    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("OpenAI API Key")
                    .font(.headline)
                
                Spacer()
                
                if KeychainService.shared.hasApiKey() {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Configured")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Required")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Text("Your API key is stored securely in the macOS Keychain.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if showingApiKeyField {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("OpenAI API Key")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        TextField("sk-...", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 32)
                            .autocorrectionDisabled()
                            .focused($isApiKeyFieldFocused)
                    }
                    
                    if let result = apiKeyTestResult {
                        HStack(spacing: 8) {
                            switch result {
                            case .success:
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("API key is valid!")
                                    .foregroundColor(.green)
                            case .failure(let error):
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .foregroundColor(.red)
                            }
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.1))
                        )
                    }
                    
                    HStack(spacing: 12) {
                        Button("Test & Save") {
                            testAndSaveApiKey()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTestingApiKey)
                        
                        Button("Save Only") {
                            saveApiKeyWithoutTest()
                        }
                        .buttonStyle(.bordered)
                        .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTestingApiKey)
                        
                        Button("Cancel") {
                            showingApiKeyField = false
                            apiKey = ""
                            apiKeyTestResult = nil
                        }
                        .buttonStyle(.bordered)
                        
                        if isTestingApiKey {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        
                        Spacer()
                    }
                }
                .padding(16)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .cornerRadius(8)
            } else {
                HStack {
                    if KeychainService.shared.hasApiKey() {
                        Button("Update API Key") {
                            showingApiKeyField = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isApiKeyFieldFocused = true
                            }
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Remove API Key") {
                            removeApiKey()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    } else {
                        Button("Add API Key") {
                            showingApiKeyField = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isApiKeyFieldFocused = true
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    Spacer()
                    
                    Link("Get API Key", destination: URL(string: "https://platform.openai.com/api-keys")!)
                        .font(.caption)
                }
            }
        }
    }
    
    // MARK: - Model Selection
    
    private var modelSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Model Selection")
                .font(.headline)
            
            Text("Choose which OpenAI model to use for conversations.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                ForEach(OpenAIModel.allCases) { model in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(model.displayName)
                                .fontWeight(.medium)
                            Text(model.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if settings.selectedModel == model {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(settings.selectedModel == model ? Color.blue.opacity(0.1) : Color.clear)
                    .cornerRadius(8)
                    .onTapGesture {
                        settings.selectedModel = model
                    }
                }
            }
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                HStack {
                    Link("GitHub Repository", destination: URL(string: "https://github.com/menubargpt/menubargpt")!)
                    Spacer()
                    Link("Privacy Policy", destination: URL(string: "https://menubargpt.com/privacy")!)
                    Spacer()
                    Link("Support", destination: URL(string: "https://menubargpt.com/support")!)
                }
                .font(.caption)
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadCurrentApiKey() {
        settings.hasApiKey = KeychainService.shared.hasApiKey()
    }
    
    private func testAndSaveApiKey() {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            apiKeyTestResult = .failure("API key cannot be empty")
            return
        }
        
        print("DEBUG: Starting API key test for key: \(String(trimmedKey.prefix(10)))...")
        
        isTestingApiKey = true
        apiKeyTestResult = nil
        
        Task {
            do {
                print("DEBUG: Testing API key with OpenAI...")
                let isValid = try await openAIClient.testApiKey(trimmedKey)
                print("DEBUG: API key test result: \(isValid)")
                
                await MainActor.run {
                    if isValid {
                        // Save the key
                        do {
                            print("DEBUG: Saving API key to keychain...")
                            try KeychainService.shared.saveApiKey(trimmedKey) // Use saveApiKey instead of saveValidatedApiKey to bypass format validation
                            settings.hasApiKey = true
                            apiKeyTestResult = .success
                            print("DEBUG: API key saved successfully!")
                            
                            // Hide the field after a delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                showingApiKeyField = false
                                apiKey = ""
                                apiKeyTestResult = nil
                            }
                        } catch {
                            print("DEBUG: Failed to save API key: \(error)")
                            apiKeyTestResult = .failure("Failed to save API key: \(error.localizedDescription)")
                        }
                    } else {
                        print("DEBUG: API key validation failed")
                        apiKeyTestResult = .failure("Invalid API key")
                    }
                    
                    isTestingApiKey = false
                }
            } catch {
                print("DEBUG: API key test error: \(error)")
                await MainActor.run {
                    apiKeyTestResult = .failure(error.localizedDescription)
                    isTestingApiKey = false
                }
            }
        }
    }
    
    private func saveApiKeyWithoutTest() {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            apiKeyTestResult = .failure("API key cannot be empty")
            return
        }
        
        print("DEBUG: Saving API key without testing...")
        
        do {
            try KeychainService.shared.saveApiKey(trimmedKey)
            settings.hasApiKey = true
            apiKeyTestResult = .success
            print("DEBUG: API key saved successfully without testing!")
            
            // Hide the field after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showingApiKeyField = false
                apiKey = ""
                apiKeyTestResult = nil
            }
        } catch {
            print("DEBUG: Failed to save API key: \(error)")
            apiKeyTestResult = .failure("Failed to save API key: \(error.localizedDescription)")
        }
    }
    
    private func removeApiKey() {
        do {
            try KeychainService.shared.deleteApiKey()
            settings.hasApiKey = false
        } catch {
            print("Failed to remove API key: \(error)")
        }
    }
    
    private func saveSettingsAndDismiss() {
        // Refresh hasApiKey status before saving
        settings.hasApiKey = KeychainService.shared.hasApiKey()
        settings.save()
        NotificationCenter.default.post(name: .settingsDidChange, object: nil)
        dismiss()
    }
}

// MARK: - Preview

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(OpenAIClient())
            .environment(\.settings, Settings.preview)
            .frame(width: 500, height: 400)
    }
}
#endif